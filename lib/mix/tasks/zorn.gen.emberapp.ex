defmodule Mix.Tasks.Zorn.Gen.Emberapp do
  use Mix.Task

  import Mix.Tasks.Zorn
  import Mix.Utils, only: [camelize: 1]

  @shortdoc "Generate an Ember application in the current project."

  @moduledoc """
  Generate an Ember application in the current project.

  ## Command line options

  * `--no-install`   - don't install NPM packages and Ruby GEMs
  * `--no-bootstrap` - don't use the Twitter Bootstrap stylesheet and JavaScripts
  * `--target PATH`  - specify the path where to generate files, defaults to current dir
  * `--app`          - name of the application to generate, defaults to current app

  ## Examples

      mix zorn.gen.emberapp
  """
  def run(args) do
    npm_is_installed!
    rubygem_is_installed!

    options = parse_arguments(args)
    context = build_context(options)
    path    = template_path("emberapp")

    Enum.map(template_files(path), fn template ->
      generate({path, template}, options[:target], context)
    end)

    if options[:install] do
      File.cd!(options[:target])
      install_npm_packages
      install_gems
    end

    display_instructions(context)
  end

  defp parse_arguments(args) do
    defaults = [
      "--bootstrap",
      "--install",
      "--target", File.cwd!,
      "--app", atom_to_binary(Mix.project[:app])
    ]
    {options, _arguments, _errors} = OptionParser.parse(defaults ++ args,
      switches: [bootstrap: :boolean, install: :boolean])
    options
  end

  defp build_context(options) do
    [ application: options[:app],
      module_name: camelize(options[:app]),
      options: options ]
  end

  def npm_is_installed! do
    command_must_succeed! "npm -v >/dev/null 2>&1",
      "Can't find command 'npm'. Please install https://www.npmjs.org/doc/install.html."
  end

  def rubygem_is_installed! do
    command_must_succeed! "gem -v >/dev/null 2>&1",
      "Can't find command 'gem'. Please install Ruby and Rubygems: https://www.ruby-lang.org/en/downloads."
  end

  defp install_npm_packages do
    Mix.shell.info "  * install npm packages"
    if Mix.shell.cmd("npm install >&2") != 0 do
      Mix.shell.error "Failed installing npm packages!"
      exit 1
    end
  end

  defp install_gems do
    if Mix.shell.cmd("gem query -i bundler") != 0 do
      Mix.shell.info "  * install bundler gem"
      Mix.shell.cmd("gem install bundler")
    end
    Mix.shell.info "  * install ruby gems"
    if Mix.shell.cmd("bundle") != 0 do
      Mix.shell.error "Failed installing npm packages!"
      exit 1
    end
  end

  defp display_instructions(context) do
    Mix.shell.info ~s"""

    %{black,bright}Ember application was generated.%{reset}

    You first must add the following to the %{black,bright}start%{reset} function in
    lib/#{context[:application]}.ex:

    %{blue,bright}#{context[:module_name]}.Router
    |> Plug.Adapters.Cowboy.http([port: 4000])%{reset}

    Then make sure you have a JSON library such as cblage/elixir-json or meh/jazz in
    your %{black,bright}mix.exs%{reset} file:

    %{blue,bright}defp deps do
      [ {:zorn, github: "mathieul/zorn"},
        {:json, github: "cblage/elixir-json"} ]
    end%{reset}

    Update your dependencies and compile your project:
    $ %{green,bright}mix do deps.get, compile%{reset}

    Compile your assets:
    $ %{green,bright}grunt%{reset}

    And finally start the web server with:
    $ %{green,bright}mix run --no-halt%{reset}

    You can then launch a brower at the URL %{black,bright}http://localhost:4000%{reset}

    You can also test the JSON API example using curl:
    %{black,bright}curl --header "Content-Type: application/json" -v http://localhost:4000/examples/42%{reset}
    """
  end
end
