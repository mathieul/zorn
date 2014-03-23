defmodule Mix.Tasks.Zorn do
  @path Path.expand('../../../priv/templates', __DIR__)

  import Mix.Generator

  def template_path(task_name),
    do: Path.join(@path, task_name)

  def template_files(path) do
    Path.wildcard("#{path}/**")
    |> Enum.map(fn file_path -> Path.relative_to(file_path, path) end)
  end

  def generate({path, template}, target, context) do
    source = Path.join(path, template)
    content = if String.ends_with?(template, ".eex") do
      EEx.eval_file(source, context)
    else
      File.read!(source)
    end

    dest_file = Path.rootname(template, ".eex")
    destination = Path.join(target, dest_file)

    create_file(destination, content)
  end

  def command_must_succeed!(command, error_message) do
    unless Mix.shell.cmd(command) == 0 do
      Mix.shell.error(error_message)
      exit 1
    end
  end
end