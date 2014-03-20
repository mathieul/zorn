defmodule Zorn.Plugs.EncodeResponseTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Zorn.Plugs.EncodeResponse

  @opts EncodeResponse.init [
    formatters: [{"application/json", &__MODULE__.encode/1},
                 {"text/plain",       &(inspect &1)}]
  ]

  def encode(object) do
    object
    |> Zorn.Parameters.camelize(:lower)
    |> JSON.encode!
  end

  test "raise an error if there's no content-type or accept header" do
    conn = Plug.Conn.new(req_headers: [])
    assert_raise Zorn.Util.BadRequest, fn ->
      EncodeResponse.call(conn, @opts)
    end
  end

  test "renders the body using the format found matching the accept header" do
    conn = conn(:get, "/", [], headers: [{"accept", "application/json"}])
    conn = Plug.Connection.assign_private(conn, :zorn_response, {200, [error_message: "hello"]})

    conn = EncodeResponse.call(conn, @opts)
    assert conn.resp_body == ~S({"errorMessage":"hello"})
    assert conn.resp_headers["content-type"] == "application/json; charset=utf-8"
    assert conn.status == 200
  end

  test "renders the body using the content type if none found matching accept" do
    conn = conn(:get, "/", [], headers: [{"content-type", "text/plain"}])
    conn = Plug.Connection.assign_private(conn, :zorn_response, {400, [error_message: "error"]})

    conn = EncodeResponse.call(conn, @opts)
    assert conn.resp_body == ~S([error_message: "error"])
    assert conn.resp_headers["content-type"] == "text/plain; charset=utf-8"
    assert conn.status == 400
  end
end
