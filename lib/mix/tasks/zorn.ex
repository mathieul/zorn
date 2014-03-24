defmodule Mix.Tasks.Zorn do
  @path Path.expand('../../../priv/templates', __DIR__)

  import Mix.Generator

  def template_path(task_name),
    do: Path.join(@path, task_name)

  def template_files(path) do
    Path.wildcard("#{path}/**")
    |> Enum.reject(&File.dir?/1)
    |> Enum.map(fn file -> Path.relative_to(file, path) end)
  end

  def generate({path, template}, target, context) do
    source = Path.join(path, template)
    content = if String.ends_with?(template, ".eex") do
      EEx.eval_file(source, context)
    else
      File.read!(source)
    end

    template
    |> destination_file(target, context)
    |> create_file(content)
  end

  defp destination_file(template, target, context) do
    dest_file =
      template
      |> String.replace("__application__", context[:application])
      |> Path.rootname(".eex")

    Path.join(target, dest_file)
  end

  def command_must_succeed!(command, error_message) do
    unless Mix.shell.cmd(command) == 0 do
      Mix.shell.error(error_message)
      exit 1
    end
  end

  def update(file, options) when is_list(options) do
    relative_file = Path.relative_to(file, File.cwd!)
    {position, pattern, insert} = update_options(options)
    content = File.read!(file)
    case split_on_pattern(content, pattern, position) do
      {beginning, ending} ->
        File.write!(file, beginning <> insert <> ending, [:write])
        Mix.shell.info "%{green}* updating%{reset} #{relative_file}"
      :no_match ->
        Mix.shell.info "%{red}* failed updating%{reset} #{relative_file}"
    end
  end

  defp update_options(options) do
    insert = Dict.fetch!(options, :insert)
    {position, pattern} = case Dict.fetch(options, :before) do
      {:ok, before} ->
        {:before, before}
      :error ->
        {:after, Dict.fetch!(options, :after)}
    end
    {position, pattern, insert}
  end

  defp split_on_pattern(content, pattern, position) do
    case Regex.run(pattern, content, return: :index) do
      [{index, length}] ->
        {rindex, lindex} = if position == :before do
          {index - 1, index}
        else
          {index - 1 + length, index + length}
        end
        {String.slice(content, 0..rindex), String.slice(content, lindex..-1)}
      _ ->
        :no_match
    end
  end
end
