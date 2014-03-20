defmodule Zorn.Plugs.EncodeResponse do
  import Plug.Connection, only: [put_resp_content_type: 2, send_resp: 3, assign_private: 3]
  import Zorn.Connection, only: [parse_accept: 1, matching_format: 2]

  alias Plug.Conn

  def init(options) do
    formatters = Dict.fetch!(options, :formatters)

    options
    |> Dict.merge(supported: Dict.keys(formatters))
  end

  def call(Conn[req_headers: headers] = conn, options) do
    accepted     = parse_accept(headers["accept"])
    content_type = headers["content-type"]

    case matching_mime_type(accepted, content_type, options[:supported]) do
      {:ok, mime_type} ->
        {code, response} = conn.private[:zorn_response]
        body = options[:formatters][mime_type].(response)
        put_resp_content_type(conn, mime_type)
        |> send_resp(code, body)

      :error ->
        raise Zorn.Util.BadRequest, message: "no format found"
    end
  end

  defp matching_mime_type(nil, content_type, supported),
    do: matching_format([content_type], supported)

  defp matching_mime_type(accepted, nil, supported),
    do: matching_format(accepted, supported)

  defp matching_mime_type(nil, nil, _),
    do: :error

  defp matching_mime_type(accepted, content_type, supported) do
    case matching_format(accepted, supported) do
      {:ok, mime_type} ->
        {:ok, mime_type}

      :error ->
        matching_format([content_type], supported)
    end
  end

  def respond_with(conn, code \\ 200, object) do
    assign_private(conn, :zorn_response, {code, object})
  end
end
