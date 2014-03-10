defmodule Zorn.Plugs.AuthenticateTokenTest do
  use ExUnit.Case, async: true
  use Plug.Test

  defmodule MyPlug do
    use Plug.Builder
    plug Zorn.Plugs.AuthenticateToken,
         cookie:  "auth_token",
         fetcher: &__MODULE__.fetch_authentified/1,
         formats: [{"application/json", ~s{{"message": "Invalid credentials"}}},
                   {"*", "Invalid credentials"}],
         except:  [post: "/", put: ~r(/test/[^/]+$)]
    plug :passthrough

    def fetch_authentified(token) do
      if token == "right-password", do: :authenticated_object, else: nil
    end

    defp passthrough(conn, _),
      do: Plug.Connection.send_resp(conn, 200, "{}")
  end

  defmodule MyPlugWithOnly do
    use Plug.Builder
    plug Zorn.Plugs.AuthenticateToken,
         fetcher: &__MODULE__.fetch_authentified/1,
         only:   [post: "/", put: ~r(/test/[^/]+$)]
    plug :passthrough

    def fetch_authentified(_token),
      do: nil

    defp passthrough(conn, _),
      do: Plug.Connection.send_resp(conn, 200, "{}")
  end

  test "return a 401 error if the token is not found" do
    conn = conn(:get, "/") |> MyPlug.call([])
    assert conn.status == 401
  end

  test "return the error specified by content type if the token is not found" do
    conn = conn(:get, "/", "", headers: [{"content-type", "application/json"}]) |> MyPlug.call([])
    assert JSON.decode!(conn.resp_body) == [{"message", "Invalid credentials"}]
  end

  test "return the default error if the if no content type and token is not found" do
    conn = conn(:get, "/") |> MyPlug.call([])
    assert conn.resp_body == "Invalid credentials"
  end

  test "skip authentication if method and path match exception list" do
    conn = conn(:post, "/") |> MyPlug.call([])
    assert conn.status == 200
  end

  test "allow regex as path matcher in except list" do
    conn = conn(:put, "/test/123") |> MyPlug.call([])
    assert conn.status == 200
    conn = conn(:put, "/test/123/edit") |> MyPlug.call([])
    assert conn.status == 401
  end

  test "allow to use :only option instead of :except" do
    conn = conn(:put, "/test/123") |> MyPlugWithOnly.call([])
    assert conn.status == 401
    conn = conn(:put, "/test/123/edit") |> MyPlugWithOnly.call([])
    assert conn.status == 200
  end

  test "return 200 if :fetch_authentified finds something" do
    conn = conn(:get, "/")
    |> put_req_cookie("auth_token", "right-password")
    |> MyPlug.call([])

    assert conn.status == 200
  end

  test "sets connection private :zorn_authentified to what :fetch_authentified returns" do
    conn = conn(:get, "/blah")
    |> put_req_cookie("auth_token", "right-password")
    |> MyPlug.call([])

    assert conn.private[:zorn_authentified] == :authenticated_object
  end
end
