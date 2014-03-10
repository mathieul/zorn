defmodule Zorn.Controller do
  import Plug.Connection

  @doc """
  Router helpers.
  """

  defmacro __using__(_options) do
    quote do
      use Plug.Router
      import Plug.Connection
      import unquote(__MODULE__)
    end
  end

  @doc """
  Forwards a connection matching given path to another router.
  """
  @spec forward(String.t, Macro.t, Plug.opts) :: Macro.t
  defmacro forward(path, plug, opts \\ []) do
    path = Path.join(path, "*glob")
    quote do
      match unquote(path) do
        conn = var!(conn).path_info(var!(glob))
        unquote(plug).call(conn, unquote(opts))
      end
    end
  end


  @doc """
  Send a response to the client with a content type.
  """
  @spec send_resp_with_type(Plug.Conn.t, Plug.Conn.status, binary, Plug.Conn.body) :: Plug.Conn.t
  def send_resp_with_type(conn, status, content_type, body) do
    put_resp_content_type(conn, content_type)
    |> send_resp(status, body)
  end

  @doc """
  Send a HTML response to the client with success status.
  """
  @spec html(Plug.Conn.t, Plug.Conn.body) :: Plug.Conn.t | no_return
  def html(conn, html),
    do: html(conn, 200, html)

  @doc """
  Send a HTML response to the client with status.
  """
  @spec html(Plug.Conn.t, Plug.Conn.status, Plug.Conn.body) :: Plug.Conn.t
  def html(conn, status, html),
    do: send_resp_with_type(conn, status, "text/html", html)

  @doc """
  Send a JSON response to the client with success status.
  """
  @spec json(Plug.Conn.t, Plug.Conn.body) :: Plug.Conn.t | no_return
  def json(conn, json),
    do: json(conn, 200, json)

  @doc """
  Send a JSON response to the client with status.
  """
  @spec json(Plug.Conn.t, Plug.Conn.status, Plug.Conn.body) :: Plug.Conn.t
  def json(conn, status, json),
    do: send_resp_with_type(conn, status, "application/json", json)

  @doc """
  Convert dict to keyword list with keys underscored and changed to atoms.
  """
  @spec camelcase_params_to_keyword_list([{ binary, binary }]) :: Keyword.t
  def camelcase_params_to_keyword_list(params) do
    params
    |> Enum.reduce(Keyword.new, fn { name, value }, attributes ->
      atomified = Mix.Utils.underscore(name) |> binary_to_atom
      Keyword.put(attributes, atomified, value)
    end)
  end
end
