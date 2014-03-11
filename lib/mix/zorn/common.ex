defmodule Mix.Zorn.Common do
  @path Path.expand('../../../priv/templates', __DIR__)

  def run_successfully_or_exit(command, error_message) do
    unless Mix.shell.cmd(command) == 0 do
      Mix.shell.error(error_message)
      exit 1
    end
  end

  def generate_file(context, name, root \\ nil) do
    Mix.shell.info "  * create file #{name}"
    path = Path.join(@path, name <> ".eex")
    dest = if nil?(root), do: name, else: Path.join(root, name)
    File.write! dest, EEx.eval_file(path, context)
    context
  end
end
