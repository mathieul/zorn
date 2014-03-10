defmodule Zorn.Plugs.AuthenticateToken do
  @behaviour Plug.Wrapper

  import Plug.Connection

  def init(options) do
    Keyword.fetch!(options, :fetcher)

    options
    |> Keyword.put_new(:cookie,  "auth_token")
    |> Keyword.put_new(:formats, [{"*", "Invalid credentials"}])
    |> set_except_or_only
  end

  defp set_except_or_only(options) do
    if except = Keyword.get(options, :except) do
      options
      |> Keyword.delete(:except)
      |> Keyword.put(:exclude, true)
      |> Keyword.put(:matches, except)
    else
      only = Keyword.get(options, :only, [])
      options
      |> Keyword.delete(:only)
      |> Keyword.put(:exclude, false)
      |> Keyword.put(:matches, only)
    end
  end

  def wrap(conn, options, fun) do
    conn = fetch_cookies(conn)
    cond do
      skip_request?(conn, options[:matches], options[:exclude]) ->
        fun.(conn)
      authentified = find_authentified(conn, options[:cookie], options[:fetcher]) ->
        assign_private(conn, :zorn_authentified, authentified)
        |> fun.()
      true ->
        send_not_authorized(conn, options[:formats])
    end
  end

  defp find_authentified(conn, cookie, fetcher) do
    if token = conn.req_cookies[cookie], do: fetcher.(token)
  end

  defp send_not_authorized(conn, formats) do
    content_type = conn.req_headers["content-type"]
    message = formats[content_type] || formats["*"]
    send_resp(conn, 401, message)
  end

  defp skip_request?(conn, matches, exclude) do
    method = request_method(conn.method)
    path = request_path(conn.path_info)
    Keyword.get_values(matches, method)
    |> Enum.any?(fn str_or_regex ->
      does_match = path_matches?(str_or_regex, path)
      if exclude, do: does_match, else: !does_match
    end)
  end

  defp request_method(string), do: string |> String.downcase |> binary_to_atom

  defp request_path(path_info), do: "/" <> Enum.join(path_info, "/")

  defp path_matches?(candidate, path) when is_binary(candidate),
    do: candidate == path

  defp path_matches?(candidate, path),
    do: Regex.match?(candidate, path)
end
