defmodule Mix.Zorn.Backend do
  alias Mix.Zorn.Common

  def init(context) do
    copy_backend_source(context, Mix.project[:app])
    Mix.shell.info "-> backend initialized.\n"
    context
  end

  defp copy_backend_source(context, application) do
    options = [root: "lib/#{application}", sub_path: "init"]
    context
    |> Common.generate_file("router.ex", options)
    |> Common.generate_file("controller/home.ex", options)
  end
end
