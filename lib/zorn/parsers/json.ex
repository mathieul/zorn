defmodule Zorn.Parsers.Json do
  @doc """
  Parses JSON, borrowed from HexWeb (https://github.com/ericmj/hex_web).
  """
  alias Plug.Conn

  def parse(Conn[] = conn, "application", "json", _headers, opts) do
    read_body(conn, Keyword.fetch!(opts, :limit))
  end

  def parse(conn, _type, _subtype, _headers, _opts) do
    { :next, conn }
  end

  defp read_body(Conn[adapter: { adapter, state }] = conn, limit) do
    case Zorn.Util.read_body({ :ok, "", state }, "", limit, adapter) do
      { :too_large, state } ->
        { :too_large, conn.adapter({ adapter, state }) }
      { :ok, "", state } ->
        { :ok, [], conn.adapter({ adapter, state }) }
      { :ok, body, state } ->
        case JSON.decode(body) do
          { :ok, params } ->
            { :ok, params, conn.adapter({ adapter, state }) }
          _ ->
            raise Zorn.Util.BadRequest, message: "malformed JSON"
        end
    end
  end
end
