defmodule Mix.Tasks.Zorn.Gen.Embermodel do
  use Mix.Task

  import Mix.Tasks.Zorn, except: [build_context: 1]
  import Inflex

  @shortdoc "Generate a new model for the Ember application in the current project."

  @moduledoc """
  Generate a new model for the Ember application in the current project.

  ## Command line options

  * `--target PATH`  - specify the path where to generate files, defaults to current dir
  * `--app`          - name of the application to generate, defaults to current app

  ## Examples

      mix zorn.gen.embermodel SUBJECT
  """
  def run(args) do
    options = parse_arguments(args)
    context = build_context(options)
    path    = template_path("embermodel")

    Enum.map(template_files(path), fn template ->
      generate({path, template}, options[:target], context)
    end)

    display_instructions(context)
  end

  def build_context(options) do
    subject = underscore(options[:subject])
    subjects = pluralize(subject) |> underscore
    Mix.Tasks.Zorn.build_context(options)
    |> Dict.merge(
      subjects:            subjects,
      subjects_camelcase:  camelize(subjects),
      subject:             subject,
      subject_camelcase:   camelize(subject)
    )
  end

  defp parse_arguments(args) do
    defaults = common_defaults
    {options, arguments, _errors} = OptionParser.parse(defaults ++ args)
    if Enum.empty?(arguments) do
      raise Mix.Error, message: "missing mandatory subject."
    end
    Dict.put(options, :subject, List.first(arguments))
  end

  defp display_instructions(context) do
    Mix.shell.info ~s"""

    %{black,bright}Done generating Ember model #{context[:subject]}.%{reset}

    You can test the JSON API example using curl:
    %{black,bright}curl --header "Content-Type: application/json" -v http://localhost:4000/#{context[:subjects]}%{reset}
    """
  end
end
