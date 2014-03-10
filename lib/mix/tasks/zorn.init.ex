defmodule Mix.Tasks.Zorn.Init do
  use Mix.Task

  @application Mix.project[:app]
  @version     Mix.project[:version]
  @path        Path.expand('../../../priv/templates', __DIR__)

  @shortdoc "Initialize current mix project for Zorn backend and frontend development."
  @moduledoc "A task to initialize Zorn"
  def run(args) do
    assert_not_initialized!
    assert_npm_installed!

    Mix.shell.info "Generating the following files:"
    build_context(args)
    |> setup_frontend
    |> setup_backend
  end

  defp assert_not_initialized! do
    if already_initialized? do
      Mix.shell.error "The current project #{@application} has already been initialized for Zorn."
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

  defp build_context(args) do
    options = parse_options(args)
    [
      application: @application,
      version: @version,
      options: options,
      bower: bower_packages(options),
      npm: npm_packages(options)
    ]
  end

  defp parse_options(args) do
    defaults = ["--sass", "--base", "--ember", "--bootstrap"]
    {options, _arguments, _errors} = OptionParser.parse(defaults ++ args,
      switches: [sass: :boolean, bourbon: :boolean, basejs: :boolean, emberjs: :boolean, boostrap: :boolean])
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
    context
    |> generate_file("package.json")
    |> generate_file("bower.json")
    |> generate_file("Gruntfile.coffee")
    if context[:options][:sass], do: generate_file(context, "Gemfile")

    install_npm_packages
    install_gems(context[:options][:sass])

    copy_assets(context)
    Mix.shell.info "-> frontend initialized."
  end

  defp generate_file(context, name) do
    Mix.shell.info "  * create file #{name}"
    path = Path.join(@path, name <> ".eex")
    File.write! name, EEx.eval_file(path, context)
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

  defp setup_backend(_context) do
    Mix.shell.info "-> backend initialized."
  end
end
