defmodule Zorn.Serializer do
  defprotocol Serializable do
    def attributes(container, kind)
    def singular(container)
    def plural(container)
  end

  defimpl Serializable, for: List do
    def attributes(list, as),
      do: Enum.map(list, &( Serializable.attributes(&1, as) ))

    def singular(_),
      do: :inexistent

    def plural(_),
      do: :collection
  end

  defimpl Serializable, for: Tuple do
    def attributes(list, _),
      do: list

    def singular(_),
      do: :tuple

    def plural(_),
      do: :collection
  end

  def serialize(object),
    do: serialize(object, [])

  def serialize([], options) when is_list(options),
    do: [{root(options), []}]

  def serialize(object, options) when is_list(options) do
    as = Dict.get(options, :as, :default)
    [{root(object, options), Serializable.attributes(object, as)}]
  end

  defp root(options),
    do: Dict.fetch!(options, :root)

  defp root([], options),
    do: root(options)

  defp root([head, _] = object, options),
    do: Serializable.plural(head)

  defp root(object, options),
    do: Serializable.singular(object)
end
