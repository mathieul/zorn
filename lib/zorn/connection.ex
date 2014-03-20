defmodule Zorn.Connection do
  @doc """
  Parse the accept header value to return an ordered list of mime type tuples.
  """
  def parse_accept(accept) do
    accept
    |> String.split(",")
    |> Enum.with_index
    |> Enum.map(fn {desc, index} ->
      case String.split(desc, ";") do
        [mime_type, <<"q=" <> qvalue>>] ->
          qvalue = parse_float(qvalue)
          {parse_mime_type(mime_type), index, qvalue}

        [mime_type] ->
          {parse_mime_type(mime_type), index, 1}
      end
    end)
    |> Enum.sort(&compare_indexed_types/2)
    |> Enum.map(&(elem(&1, 0)))
  end

  defp parse_mime_type(mime_type) do
    case String.split(mime_type, "/") do
      [type, subtype] -> {type, subtype}
      [subtype] -> {"unknown", subtype}
    end
  end

  defp parse_float(string) do
    case Float.parse(string) do
      [float, _] -> float
      _ -> 1.0
    end
  end

  defp compare_indexed_types({_, ai, aq}, {_, bi, bq}) do
    cond do
      aq > bq -> true
      aq == bq and ai < bi -> true
      true -> false
    end
  end

  @doc """
  Return the format matching both accepted subtypes and supported formats.
  """
  def matching_format(accepted, supported) when is_list(accepted) and is_list(supported) do
    found =
      accepted
      |> Enum.map(fn {_, subtype} -> subtype end)
      |> Enum.find(fn subtype -> subtype in supported or subtype == "*" end)

    case found do
      "*"    -> {:ok, List.first(supported)}
      nil    -> :error
      format -> {:ok, format}
    end
  end

  @doc """
  Read the body from a Plug connection (borrowed from HexWeb (https://github.com/ericmj/hex_web)).

  Should be in Plug proper eventually and can be removed at that point.
  """
  def read_body({ :ok, buffer, state }, acc, limit, adapter) when limit >= 0,
    do: read_body(adapter.stream_req_body(state, 1_000_000), acc <> buffer, limit - byte_size(buffer), adapter)
  def read_body({ :ok, _, state }, _acc, _limit, _adapter),
    do: { :too_large, state }

  def read_body({ :done, state }, acc, limit, _adapter) when limit >= 0,
    do: { :ok, acc, state }
  def read_body({ :done, state }, _acc, _limit, _adapter),
    do: { :too_large, state }
end
