defmodule <%= module_name %>.Controller.API do
  defmacro __using__(options) do
    quote do
      use Plug.Router

      import Plug.Connection
      import Zorn.Plugs.EncodeResponse, only: [respond_with: 2, respond_with: 3]
      import Zorn.Serializer
      import Zorn.Parameters
      import unquote(__MODULE__)

      plug Plug.Parsers, parsers: [Zorn.Parsers.Json]
      plug Plug.MethodOverride
      plug :match
      plug :dispatch
      plug Zorn.Plugs.EncodeResponse, formatters: [
        {"application/json", &encode_json_low_camel_case_keys/1},
        {"text/plain", &(inspect &1)}
      ]
    end
  end

  def encode_json_low_camel_case_keys(response) do
      response
      |> Zorn.Parameters.camelize(:lower)
      |> JSON.encode!
  end

  # add functions accessible by all controllers here:
  # ...
end
