defmodule Mix.Zorn.Backend do
  alias Mix.Zorn.Common

  def setup(context) do
    create_directories(Mix.project[:app])
    copy_backend_source(context, Mix.project[:app])
    Mix.shell.info "-> backend initialized.\n"
    context
  end

  defp create_directories(application) do
    ~W[collection model controller]
    |> Enum.each(fn name -> File.mkdir_p!("./lib/#{application}/#{name}") end)
  end

  defp copy_backend_source(context, application) do
    context
    |> Common.generate_file("router.ex", "lib/#{application}")
    |> Common.generate_file("controller/home.ex", "lib/#{application}")
    |> Common.generate_file("controller/api.ex", "lib/#{application}")
    |> Common.generate_file("controller/todos.ex", "lib/#{application}")
  end
end
