defprotocol Zorn.Serializer do
  @spec serialize(t) :: term
  def serialize(model)

  @spec serialize(t, atom) :: term
  def serialize(model, root)

  @spec model_name(t) :: binary
  def model_name(model)

  @spec collection_name(t) :: binary
  def collection_name(model)
end

defimpl Zorn.Serializer, for: List do
  def serialize([]),
    do: []

  def serialize(list),
    do: serialize(list, collection_name([]))

  def serialize(list, root) do
    serialized_content = Enum.map(list, fn item ->
      [{_, content}] = Zorn.Serializer.serialize(item)
      content
    end)

    [{root, serialized_content}]
  end

  def model_name(_),
    do: :model

  def collection_name(_),
    do: :collection
end
