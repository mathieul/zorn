defmodule Mix.Tasks.Zorn.Init do
  use Mix.Task

  @path Path.expand('../../../priv/templates', __DIR__)

  @shortdoc "Initialize current mix project for Zorn backend and frontend development."
  @moduledoc "A task to initialize Zorn"
  def run(args) do
    options = parse_options(args)

    unless options[:force], do: assert_not_initialized!
    assert_npm_installed!

    Mix.shell.info "Generating the following files:"
    build_context(options)
    |> setup_frontend
    |> setup_backend
    |> display_instructions
  end

  defp assert_not_initialized! do
    if already_initialized? do
      Mix.shell.error "The current project #{Mix.project[:app]} has already been initialized for Zorn."
      exit 1
    end
  end

  defp assert_npm_installed! do
    unless Mix.shell.cmd("npm -v >/dev/null 2>&1") == 0 do
      Mix.shell.error "Can't find command 'npm'. Please install https://www.npmjs.org/doc/install.html."
      exit 1
    end
  end

  defp assert_rubygem_installed! do
    unless Mix.shell.cmd("gem -v >/dev/null 2>&1") == 0 do
      Mix.shell.error "Can't find command 'gem'. Please install Ruby and Rubygems: https://www.ruby-lang.org/en/downloads."
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
      bower:       bower_packages(options),
      npm:         npm_packages(options)
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
    if options[:sass], do: assert_rubygem_installed!
    options
  end

  defp bower_packages(options) do
    packages = []
    if options[:base] do
      packages = packages ++ [jquery: "~2.0.0", underscore: "~1.5.2", momentjs: "~2.5.1"]
    end
    if options[:ember] do
      packages = packages ++ [ember: "~1.4.0", "ember-data": "~1.0.0-beta.7"]
    end
    if options[:bootstrap] do
      packages = packages ++ ["bootstrap-sass-official": "~3.1.0"]
    end
    packages
  end

  defp npm_packages(options) do
    packages = [grunt: "~0.4.2", "grunt-contrib-uglify": "~0.3.2",
      "grunt-contrib-concat": "~0.3.0", "grunt-contrib-coffee": "~0.10.1",
      "grunt-ember-templates": "~0.4.18", "grunt-bower-task": "~0.3.4",
    "grunt-contrib-watch": "~0.5.3", "grunt-contrib-copy": "~0.5.0"]
    if options[:sass], do: packages = packages ++ [  "grunt-contrib-sass": "~0.7.2"]
    if options[:ember] do
      packages = packages ++ ["handlebars": "~1.3.0", "ember-template-compiler": "~1.4.0-beta.1"]
    end
    packages
  end

  defp setup_frontend(context) do
    options = context[:options]

    context
    |> generate_file("package.json")
    |> generate_file("bower.json")
    |> generate_file("Gruntfile.coffee")
    if options[:sass], do: generate_file(context, "Gemfile")

    if options[:commands] do
      install_npm_packages
      install_gems(options[:sass])
    end

    copy_assets(context)
    Mix.shell.info "-> frontend initialized."
    context
  end

  defp generate_file(context, name, root \\ nil) do
    Mix.shell.info "  * create file #{name}"
    path = Path.join(@path, name <> ".eex")
    dest = if nil?(root), do: name, else: Path.join(root, name)
    File.write! dest, EEx.eval_file(path, context)
    context
  end

  defp install_npm_packages do
    Mix.shell.info "  * install npm packages"
    if Mix.shell.cmd("npm install >&2") != 0 do
      Mix.shell.error "Failed installing npm packages!"
      exit 1
    end
  end

  defp install_gems(false), do: Mix.shell.info "  * skip ruby gems"
  defp install_gems(_) do
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

  defp copy_assets(context) do
    File.mkdir_p!("./assets/stylesheets")
    generate_file(context, "assets/stylesheets/application.scss")
    File.mkdir_p!("./assets/javascripts")
    generate_file(context, "assets/javascripts/application.coffee")
  end

  defp setup_backend(context) do
    create_directories(Mix.project[:app])
    copy_backend_source(context, Mix.project[:app])
    Mix.shell.info "-> backend initialized."
    context
  end

  defp create_directories(application) do
    ~W[collection model controller]
    |> Enum.each(fn name -> File.mkdir_p!("./lib/#{application}/#{name}") end)
  end

  defp copy_backend_source(context, application) do
    context
    |> generate_file("controller/home.ex", "lib/#{application}")
    |> generate_file("controller/api.ex", "lib/#{application}")
    |> generate_file("controller/todos.ex", "lib/#{application}")
  end

  defp display_instructions(context) do
    Mix.shell.info ~s"""


    Zorn initialization has finished.

    You first must add the following to the start function in
    lib/#{context[:application]}.ex:

    %{blue,bright}#{context[:module_name]}.Router
    |> Plug.Adapters.Cowboy.http([port: 4000])%{reset}

    You then need to compile your assets with:
    $ %{green,bright}grunt%{reset}

    And finally start the web server with:
    $ %{green,bright}mix run --no-halt%{reset}
    """
    context
  end
end
