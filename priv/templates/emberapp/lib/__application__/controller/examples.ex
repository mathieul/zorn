defmodule <%= module_name %>.Controller.Examples do
  use <%= module_name %>.Controller.API

  get "/:id" do
    case find_example(id) do
      {:ok, example} ->
        respond_with(conn, serialize(example))

      :not_found ->
        respond_with(conn, 404, messages: "example ##{id} was not found")
    end
  end

  post "/" do
    case create_example(example_params(conn)) do
      {:ok, example} ->
        respond_with(conn, 201, serialize(example))

      {:errors, messages} ->
        respond_with(conn, 422, messages: messages)
    end
  end

  match _, do: respond_with(conn, 404, message: "Not Found")

  defp find_example(id) do
    {:ok, [id: id, name: "Example ##{id}", message: "code example"]}
  end

  defp create_example(_attributes) do
    {:errors, ["some kind of error message", "another error message"]}
  end

  defp example_params(conn) do
    conn.params
    |> requires(example: [:name])
    |> permits(example: [:message])
    |> fetch(:example)
  end
end
