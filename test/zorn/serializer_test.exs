defmodule Zorn.Plugs.SerializerTest do
  use ExUnit.Case, async: true

  alias Zorn.Serializer

  test "serialize a keyword list" do
    obj = [allo: "la terre", ici: "londres"]
    assert Serializer.serialize(obj) == [collection: [allo: "la terre", ici: "londres"]]
  end

  test "serialize a ListDict" do
    obj = Enum.into([{"allo", "la terre"}, {"ici", "londres"}], ListDict.new)
    assert Serializer.serialize(obj) == [collection: [{"allo", "la terre"}, {"ici", "londres"}]]
  end

  defrecord Person, first_name: nil, last_name: nil, age: nil, genre: nil

  defimpl Zorn.Serializer.Serializable, for: Person do
    def attributes(person),
      do: person.to_keywords |> Dict.take([:first_name, :last_name, :age])
    def singular(_), do: :person
    def plural(_), do: :people
  end

  test "serialize a Person" do
    obj = Person.new(first_name: "Serge", last_name: "Gainsbourg", age: 62, genre: "male")
    assert Serializer.serialize(obj) == [person: [first_name: "Serge", last_name: "Gainsbourg", age: 62]]
  end

  test "serialize a list of people" do
    serge = Person.new(first_name: "Serge", last_name: "Gainsbourg", age: 62, genre: "male")
    fiona = Person.new(first_name: "Fiona", last_name: "Apple", age: 36, genre: "female")
    assert Serializer.serialize([serge, fiona]) == [
      people: [
        [first_name: "Serge", last_name: "Gainsbourg", age: 62],
        [first_name: "Fiona", last_name: "Apple", age: 36]
      ]
    ]
  end
end
