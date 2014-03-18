defmodule Zorn.Parameters do
  defexception BadRequest, [:message] do
    defimpl Plug.Exception do
      def status(_exception),
        do: 400
    end
  end

  @doc """
  Format specified keys so it can be used to process params as permitted or required.
  """
  def specified_keys(definitions, remaining) do
    empty_specs = %{combinations: [], remaining: [], value: %{}, nested: %{}}
    Enum.reduce(definitions, empty_specs, fn definition, specs ->
      case definition do
        key when is_atom(key) ->
          add_specification_for_key(specs, key, remaining == :track)

        {key, content} when is_atom(key) ->
          nested = specified_keys(content, remaining)
          specs = %{specs | nested: Dict.put(specs.nested, key, nested)}
          add_specification_for_key(specs, key, remaining == :track)

        _ ->
          raise ArgumentError, "key specification required to be an atom or a list."
      end
    end)
  end

  defp combinations_for_key(key) do
    key_string = atom_to_binary(key)
    [key_string, key, camelize(key_string, :lower)] |> Enum.uniq
  end

  defp value_map(combinations, value) do
    Enum.reduce(combinations, %{}, fn combination, acc ->
      Dict.put(acc, combination, value)
    end)
  end

  defp add_specification_for_key(specs, key, track_remaining) do
    combinations = combinations_for_key(key)
    value = value_map(combinations, key)
    if track_remaining, do: specs = %{specs | remaining: [key | specs.remaining]}

    %{specs |
      combinations: List.flatten(specs.combinations, combinations),
      value: Dict.merge(specs.value, value)}
  end

  @doc """
  Specify which parameters are permitted.
  """
  def permits([], _),
    do: []

  def permits(params, keys) when is_list(params) and is_list(keys) do
    do_mark_when_ok(params, [], [], specified_keys(keys, :skip))
  end

  def permits(params, key) when is_list(params) and is_atom(key),
    do: permits(params, [key])

  def permits(_, _) do
    raise ArgumentError, "permits() expects a list dictionnary and a list of key requirements."
  end

  @doc """
  Specify which parameters are required.
  """
  def requires([], _),
    do: []

  def requires(params, keys) when is_list(params) and is_list(keys) do
    specs = specified_keys(keys, :track)
    do_mark_when_ok(params, [], specs.remaining, specs)
  end

  def requires(params, key) when is_list(params) and is_atom(key),
    do: requires(params, [key])

  def requires(_, _) do
    raise ArgumentError, "requires() expects a list dictionnary and a list of key requirements."
  end

  # Mark specified params as ok.
  defp do_mark_when_ok([param | rest], acc, remaining, specs) do
    case do_mark_when_ok(param, specs) do
      {:ok, name, _} = param ->
        remaining = List.delete(remaining, name)
        do_mark_when_ok(rest, [param | acc], remaining, specs)
      param ->
        do_mark_when_ok(rest, [param | acc], remaining, specs)
    end
  end

  defp do_mark_when_ok([], params, [], _),
    do: Enum.reverse(params)

  defp do_mark_when_ok([], _, [remaining], _) do
    raise BadRequest, message: "missing mandatory parameter #{remaining}"
  end

  defp do_mark_when_ok([], _, remaining, _) do
    missing = remaining |> Enum.reverse |> Enum.join(", ")
    raise BadRequest, message: "missing mandatory parameters #{missing}"
  end

  defp do_mark_when_ok({name, value}, specs) do
    if name in specs.combinations do
      name = specs.value[name]
      nested = specs.nested[name]
      if is_list(value), do: value = do_mark_when_ok(value, [], nested.remaining, nested)
      {:ok, name, value}
    else
      {name, value}
    end
  end

  defp do_mark_when_ok({:ok, name, value}, specs) do
    nested = specs.nested[name]
    if is_list(value) && nested, do: value = do_mark_when_ok(value, [], nested.remaining, nested)
    {:ok, name, value}
  end

  defp do_mark_when_ok(value, _) do
    raise ArgumentError, "permits() expects each #{inspect value} to be a key/value tuple."
  end

  @doc """
  Fetch all params marked as ok.
  """
  def fetch(params),
    do: Enum.filter_map(params, &marked_ok?/1, &strip_ok/1)

  def fetch(params, key) when is_atom(key) do
    params
    |> fetch
    |> Dict.fetch!(key)
  end

  defp marked_ok?({:ok, _, _}), do: true
  defp marked_ok?(_), do: false

  defp strip_ok({:ok, name, value}) when is_list(value),
    do: {name, fetch(value)}

  defp strip_ok({:ok, name, value}),
    do: {name, value}

  @doc """
  Convert the keys to return a parameter list with underscored binary keys.
  """
  def underscore(params) when is_list(params),
    do: do_transform(params, &underscore/1)

  def underscore(atom) when is_atom(atom),
    do: atom_to_binary(atom) |> underscore

  def underscore(string) when is_binary(string),
    do: Mix.Utils.underscore(string)

  @doc """
  Convert the keys to return a parameter list with underscored binary keys.
  """
  def camelize(something),
    do: camelize(something, :upper)

  def camelize(params, kind) when is_list(params) do
    do_transform(params, fn key -> camelize(key, kind) end)
  end

  def camelize(atom, kind) when is_atom(atom),
    do: atom_to_binary(atom) |> camelize(kind)

  def camelize(string, :lower) when is_binary(string) do
    [first|rest] =
      Mix.Utils.camelize(string)
      |> String.codepoints
    Enum.join([String.downcase(first) | rest])
  end

  def camelize(string, :upper) when is_binary(string),
    do: Mix.Utils.camelize(string)

  def camelize("", _), do: ""

  @doc """
  Convert the keys to return a parameter list with atoms.
  WARNING: only run on controlled limited set of keys to avoid leaks.
  """
  def atomify(params) when is_list(params),
    do: do_transform(params, &atomify/1)

  def atomify(atom) when is_atom(atom),
    do: atom

  def atomify(string) when is_binary(string),
    do: binary_to_atom(string)

  defp do_transform(params, fun) do
    Enum.map(params, fn item ->
      case item do
        {name, value} ->
          if is_list(value) do
            {fun.(name), fun.(value)}
          else
            {fun.(name), value}
          end
        value ->
          value
      end
    end)
  end
end
