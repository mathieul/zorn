defmodule Mix.Zorn.Frontend do
  alias Mix.Zorn.Common

  def init(context) do
    options = context[:options]

    context
    |> Common.generate_file("package.json", sub_path: "init")
    |> Common.generate_file("bower.json", sub_path: "init")
    |> Common.generate_file("Gruntfile.coffee", sub_path: "init")
    if options[:sass], do: Common.generate_file(context, "Gemfile", sub_path: "init")

    if options[:commands] do
      install_npm_packages
      install_gems(options[:sass])
    end

    copy_assets(context)
    Mix.shell.info "-> frontend initialized.\n"
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
    Common.generate_file(context, "assets/stylesheets/application.scss", sub_path: "init")
    File.mkdir_p!("./assets/javascripts")
    Common.generate_file(context, "assets/javascripts/application.coffee", sub_path: "init")
  end

  def bower_packages(options) do
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

  def npm_packages(options) do
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

  def assert_npm_installed! do
    Common.run_successfully_or_exit "npm -v >/dev/null 2>&1",
      "Can't find command 'npm'. Please install https://www.npmjs.org/doc/install.html."
  end

  def assert_rubygem_installed! do
    Common.run_successfully_or_exit "gem -v >/dev/null 2>&1",
      "Can't find command 'gem'. Please install Ruby and Rubygems: https://www.ruby-lang.org/en/downloads."
  end
end
