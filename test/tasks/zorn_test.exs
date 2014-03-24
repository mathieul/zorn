defmodule Mix.Tasks.ZornTest do
  use ExUnit.Case, async: true

  import Mix.Tasks.Zorn

  @target Path.expand("../../tmp/zorn_test", __DIR__)

  setup do
    File.rm_rf!(@target) && :ok
  end

  teardown_all do
    File.rm_rf!(@target) && :ok
  end

  test "#template_path returns the template path for a task" do
    path = template_path("test")
    assert String.ends_with?(path, "templates/test")
  end

  test "#template_files returns all the templates" do
    files =
      "test"
      |> template_path
      |> template_files
      |> Enum.sort

    assert files == ["dynamic.txt.eex", "plain.txt"]
  end

  test "generate a plain file" do
    path = template_path("test")
    silent fn ->
      generate({path, "plain.txt"}, @target, [application: "whatever"])
    end
    generated = File.read!(Path.join(@target, "plain.txt"))
    assert Regex.match?(~r(\ABob Loblaw Law Blog), generated)
  end

  test "generate a dynamic file" do
    path = template_path("test")
    silent fn ->
      generate({path, "dynamic.txt.eex"}, @target, [application: "whatever"])
    end
    generated = File.read!(Path.join(@target, "dynamic.txt"))
    assert generated == "application: whatever\n"
  end

  test "update file with content before a pattern" do
    path = template_path("test")
    destination = Path.join(@target, "plain.txt")
    silent fn ->
      generate({path, "plain.txt"}, @target, [application: "whatever"])
      update(destination, before: ~r{  forward "/",}, with: ~s{  forward "/examples", to: Hello\n})
    end
    generated = File.read!(destination)
    assert generated == """
Bob Loblaw Law Blog
test do
  forward "/examples", to: Hello
  forward "/", to: Blah
end
"""
  end

  defp silent(block) do
    ExUnit.CaptureIO.capture_io(block)
  end
end
