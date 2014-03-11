defmodule Mix.Zorn.Common do
  @path Path.expand('../../../priv/templates', __DIR__)

  def run_successfully_or_exit(command, error_message) do
    unless Mix.shell.cmd(command) == 0 do
      Mix.shell.error(error_message)
      exit 1
    end
  end

  def generate_file(context, name, options \\ []) do
    root = Keyword.get(options, :root, nil)
    sub_path = Keyword.fetch!(options, :sub_path)

    Mix.shell.info "  * create file #{name}"
    source = Path.join([@path, sub_path, name <> ".eex"])
    destination = path_for(name, root)
    ensure_dir_exists!(destination)
    File.write! destination, EEx.eval_file(source, context)
    context
  end

  defp path_for(name, nil),
    do: name
  defp path_for(name, root),
    do: Path.join(root, name)

  defp ensure_dir_exists!(path),
    do: Path.dirname(path) |> File.mkdir_p!
end
