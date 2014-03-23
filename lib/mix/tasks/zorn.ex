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
    |> destination_file(target, context[:options])
    |> create_file(content)
  end

  defp destination_file(template, target, options) do
    dest_file =
      template
      |> String.replace("__application__", options[:application])
      |> Path.rootname(".eex")

    Path.join(target, dest_file)
  end

  def command_must_succeed!(command, error_message) do
    unless Mix.shell.cmd(command) == 0 do
      Mix.shell.error(error_message)
      exit 1
    end
  end
end
