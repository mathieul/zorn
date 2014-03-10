defmodule Zorn.PlugTestHelper do
  @router :not_set

  defmacro __using__(options) do
    router = Keyword.fetch!(options, :router)
    quote do
      use Plug.Test
      import unquote(__MODULE__)
      Module.put_attribute(__MODULE__, :router, unquote(router))

      def json_request(method, path, data, cookies \\ []) do
        json = JSON.encode!(data)
        conn = conn(method, path, json, headers: [{ "content-type", "application/json" }])
        conn = Enum.reduce(cookies, conn, fn {name, value}, conn ->
          put_req_cookie(conn, name, value)
        end)
        @router.call(conn, [])
      end
    end
  end
end
