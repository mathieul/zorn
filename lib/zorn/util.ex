defmodule Zorn.Util do
  @moduledoc """
  Utility functions borrowed from HexWeb (https://github.com/ericmj/hex_web).
  """

  defexception BadRequest, [:message] do
    defimpl Plug.Exception do
      def status(_exception) do
        400
      end
    end
  end

  @doc """
  Converts an ecto datetime record to ISO 8601 format.
  """
  @spec to_iso8601(Ecto.DateTime.t) :: String.t
  def to_iso8601(Ecto.DateTime[] = dt) do
    "#{pad(dt.year, 4)}-#{pad(dt.month, 2)}-#{pad(dt.day, 2)}T" <>
    "#{pad(dt.hour, 2)}:#{pad(dt.min, 2)}:#{pad(dt.sec, 2)}Z"
  end

  defp pad(int, padding) do
    str = to_string(int)
    padding = max(padding - byte_size(str), 0)
    do_pad(str, padding)
  end

  defp do_pad(str, 0), do: str
  defp do_pad(str, n), do: do_pad("0" <> str, n - 1)
end
