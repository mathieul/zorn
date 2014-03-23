defrecord <%= module_name %>.Model.Example, id: nil, name: "", message: ""

defimpl Zorn.Serializer, for: <%= module_name %>.Model.Example do
  def serialize(example),
    do: serialize(example, model_name(example))

  def serialize(example, root),
    do: [{root, serialize_attributes(example)}]

  defp serialize_attributes(example) do
    [id: example.id, name: example.name, message: example.message]
  end

  def model_name(_example),
    do: :example

  def collection_name(_example),
    do: :examples
end
