defmodule Zorn.Plugs.EncodeResponse do
  import Plug.Connection, only: [put_resp_content_type: 2, send_resp: 3, assign_private: 3]
  import Zorn.Parameters, only: [camelize: 2]

  alias Plug.Conn

  def init(options),
    do: options

  def call(Conn[req_headers: req_headers] = conn, options) do
    case List.keyfind(req_headers, "content-type", 0) do
      {"content-type", content_type} ->
        case Plug.Connection.Utils.content_type(content_type) do
          {:ok, _type, subtype, _headers} ->
            {code, response} = conn.private[:zorn_response]
            body = encode(response, subtype, options[:keys])
            put_resp_content_type(conn, content_type)
            |> send_resp(code, body)
          :error ->
            conn
        end
      nil ->
        conn
    end
  end

  defp encode(response, format, transformation) do
    response
    |> transform(transformation)
    |> encode(format)
  end

  defp encode(response, "json"),
    do: JSON.encode!(response)

  defp encode(response, _format),
    do: inspect(response)

  defp transform(response, :lower_camel_case),
    do: camelize(response, :lower)

  defp transform(response, :upper_camel_case),
    do: camelize(response, :upper)

  defp transform(response, nil),
    do: response

  def respond_with(conn, code \\ 200, object) do
    assign_private(conn, :zorn_response, {code, object})
  end
end
