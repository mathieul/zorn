defmodule Zorn.Plugs.ConnectionTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Zorn.Connection

  test "parse accept header: */*;q=0.9" do
    assert Connection.parse_accept("*/*;q=0.9") == ["*/*"]
  end

  test "parse accept header: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" do
    accept = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
    assert Connection.parse_accept(accept) == [
      "text/html", "application/xhtml+xml", "application/xml", "*/*"
    ]
  end

  test "parse application/json, text/javascript, */*; q=0.01" do
    accept = "application/json, text/javascript, */*; q=0.01"
    assert Connection.parse_accept(accept) == [
      "application/json", "text/javascript", "*/*"
    ]
  end

  test "parse missing accept header" do
    assert Connection.parse_accept(nil) == []
  end

  test "return the first format supported that matches the subtypes accepted" do
    accepted = ["application/json", "text/javascript"]
    supported = ["text/xml", "text/javascript"]
    assert Connection.matching_format(accepted, supported) == {:ok, "text/javascript"}
  end

  test "return the first format supported when none accepted matches but */*" do
    accepted = ["text/html", "text/xml", "*/*"]
    supported = ["application/json", "text/plain"]
    assert Connection.matching_format(accepted, supported) == {:ok, "application/json"}
  end

  test "return :error if no format supported matches accepted subtypes" do
    accepted = ["text/html", "text/xml"]
    supported = ["application/json", "text/plain"]
    assert Connection.matching_format(accepted, supported) == :error
  end
end
