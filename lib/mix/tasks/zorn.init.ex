defmodule Mix.Tasks.Zorn.Init do
  use Mix.Task

  @application Mix.project[:app]
  @version     Mix.project[:version]
  @path        Path.expand('../../../priv/templates', __DIR__)

  @shortdoc "Initialize current mix project for Zorn backend and frontend development."
  @moduledoc "A task to initialize Zorn"
  def run(args) do
    if already_initialized? do
      Mix.shell.error "The current project #{@application} has already been initialized for Zorn."
      exit 1
    end
    build_context(args)
    |> setup_frontend
    |> setup_backend
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
      bower: bower_packages(options)
    ]
  end

  defp parse_options(args) do
    defaults = ["--sass", "--base", "--ember", "--bootstrap"]
    {options, _arguments, _errors} = OptionParser.parse(defaults ++ args,
      switches: [sass: :boolean, bourbon: :boolean, basejs: :boolean, emberjs: :boolean, boostrap: :boolean])
    if options[:bootstrap] || options[:bourbon] do
      options = Keyword.put(options, :sass, true)
    end
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

  defp setup_frontend(context) do
    context
    |> generate_file("package.json")
    |> generate_file("bower.json")
    |> generate_file("Gruntfile.coffee")
#    generate_gemfile
    IO.puts "-> frontend initialized."
  end

  defp generate_file(context, name) do
    Mix.shell.info "  * #{name}"
    path = Path.join(@path, name <> ".eex")
    File.write! name, EEx.eval_file(path, context)
  end

  defp setup_backend(_context) do
    IO.puts "-> backend initialized."
  end
end
