defmodule Zorn.Serializer do
  defprotocol Serializable do
    def attributes(container)
    def singular(container)
    def plural(container)
  end

  def serialize([head, _] = object),
    do: serialize(object, Serializable.plural(head))

  def serialize(object),
    do: serialize(object, Serializable.singular(object))

  def serialize([], root),
    do: [root, []]

  def serialize(object, root) do
    [{root, Serializable.attributes(object)}]
  end

  defimpl Serializable, for: List do
    def attributes(list),
      do: Enum.map(list, &Serializable.attributes/1)

    def singular(_),
      do: :inexistent

    def plural(_),
      do: :collection
  end

  defimpl Serializable, for: Tuple do
    def attributes(list),
      do: list

    def singular(_),
      do: :tuple

    def plural(_),
      do: :collection
  end
end
