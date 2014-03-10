defmodule Zorn.Plugs.CommonLogger do
  @doc """
  Plug borrowed from pull request: https://github.com/elixir-lang/plug/pull/18.
  """
  @behaviour Plug.Wrapper

  def init(options) do
    Keyword.put_new(options, :fun, &IO.puts/1)
  end

  def wrap(conn, options, fun) do
    conn = fun.(conn)
    log(conn, options)
    conn
  end

  defp log(Plug.Conn[resp_headers: resp_headers, status: status] = conn, options) do
    fun = Keyword.get(options, :fun)

    path = "/" <> Enum.join(conn.path_info, "/")
    request_path = case conn.query_string do
      "" -> path
      _  -> "#{path}?#{conn.query_string}"
    end

    request = "#{conn.method} #{request_path} HTTP/1.1"
    date = format_date(:erlang.universaltime)
    bytes = resp_headers["content-length"] || "-"

    # remotehost authuser [date] "request" status bytes
    fun.("- - [#{date}] \"#{request}\" #{status} #{bytes}")
  end

  defp format_date({{year, month, day}, {hour, minute, second}}) do
    # ex: 07/Aug/2006:23:58:02 -0400
    format = "~2.10.0B/~s/~4.10.0B:~2.10.0B:~2.10.0B:~2.10.0B +0000"
    month = :httpd_util.month(month)
    formated_date = :io_lib.format(format, [day, month, year, hour, minute, second])
    to_string(formated_date)
  end
end
