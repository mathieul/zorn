defmodule Mix.Tasks.Zorn.Init do
  use Mix.Task

  alias Mix.Zorn.Backend
  alias Mix.Zorn.Frontend

  @shortdoc "Initialize current mix project for Zorn backend and frontend development."
  @moduledoc "A task to initialize Zorn"
  def run(args) do
    options = parse_options(args)

    unless options[:force], do: assert_not_initialized!
    Frontend.assert_npm_installed!

    Mix.shell.info "Generating the following files:"
    build_context(options)
    |> Frontend.init
    |> Backend.init
    |> display_instructions
  end

  defp assert_not_initialized! do
    if already_initialized? do
      Mix.shell.error "The current project #{Mix.project[:app]} has already been initialized for Zorn."
      exit 1
    end
  end

  defp already_initialized? do
    File.exists?("Gruntfile.coffee")
  end

  defp build_context(options) do
    [
      application: Mix.project[:app],
      module_name: (Mix.project[:app] |> atom_to_binary |> Mix.Utils.camelize),
      version:     Mix.project[:version],
      options:     options,
      bower:       Frontend.bower_packages(options),
      npm:         Frontend.npm_packages(options)
    ]
  end

  defp parse_options(args) do
    defaults = ["--commands", "--sass", "--base", "--bootstrap"]
    {options, _arguments, _errors} = OptionParser.parse(defaults ++ args,
      switches: [sass: :boolean, bourbon: :boolean, basejs: :boolean, force: :boolean,
                 emberjs: :boolean, boostrap: :boolean, commands: :boolean])
    if options[:bootstrap] || options[:bourbon] do
      options = Keyword.put(options, :sass, true)
    end
    if options[:sass], do: Frontend.assert_rubygem_installed!
    options
  end

  defp display_instructions(context) do
    Mix.shell.info ~s"""
    %{black,bright}Zorn initialization has finished.%{reset}

    You first must add the following to the start function in
    lib/#{context[:application]}.ex:

    %{blue,bright}#{context[:module_name]}.Router
    |> Plug.Adapters.Cowboy.http([port: 4000])%{reset}

    You then need to compile your assets with:
    $ %{green,bright}grunt%{reset}

    And finally start the web server with:
    $ %{green,bright}mix run --no-halt%{reset}

    You can test using curl for instance:
    $ %{green,bright}curl -v http://localhost:4000/todos/hello-there%{reset}
    """
    context
  end
end
