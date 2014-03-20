defmodule Zorn.ParametersTest do
  use ExUnit.Case

  import Zorn.Parameters

  test "building specified keys" do
    specification = [:a_name, :another_one, first_level: [:flat, second_level: [:with_bumps]]]
    assert specified_keys(specification, :track) == %{
      combinations: ["a_name", :a_name, "aName", "another_one", :another_one, "anotherOne",
                     "first_level", :first_level, "firstLevel"],
      remaining: [:first_level, :another_one, :a_name],
      value: %{
        "a_name" => :a_name,
        :a_name  => :a_name,
        "aName"  => :a_name,
        "another_one" => :another_one,
        :another_one  => :another_one,
        "anotherOne"  => :another_one,
        "first_level" => :first_level,
        :first_level  => :first_level,
        "firstLevel"  => :first_level
      },
      nested: %{
        first_level: %{
          combinations: ["flat", :flat, "second_level", :second_level, "secondLevel"],
          remaining: [:second_level, :flat],
          value: %{
            "flat" => :flat,
            :flat  => :flat,
            "second_level" => :second_level,
            :second_level  => :second_level,
            "secondLevel"  => :second_level
          },
          nested: %{
            second_level: %{
              combinations: ["with_bumps", :with_bumps, "withBumps"],
              remaining: [:with_bumps],
              value: %{
                "with_bumps" => :with_bumps,
                :with_bumps  => :with_bumps,
                "withBumps"  => :with_bumps
              },
              nested: %{}
            }
          }
        }
      }
    }
  end

  test "permits a single key" do
    assert permits([{"id", "123"}], [:id]) == [{:ok, :id, "123"}]
  end

  test "permits a single key with camel cased key" do
    params = [{"firstName", "John"}]
    assert permits(params, [:first_name]) == [{:ok, :first_name, "John"}]
  end

  test "permits keys on 2 level deep params" do
    params = [{"account", [{"firstName", "John"}, {"lastName", "Zorn"}]}]
    assert permits(params, [account: [:first_name]]) == [
      {:ok, :account, [{:ok, :first_name, "John"}, {"lastName", "Zorn"}]}
    ]
  end

  test "doesn't raise an error if a permitted key is missing" do
    assert permits([{"test_id", "456"}], [:id]) == [{"test_id", "456"}]
  end

  test "chain permits" do
    permitted =
      [{"firstName", "John"}, {"lastName", "Zorn"}]
      |> permits([:email])
      |> permits([:last_name])
    assert permitted == [{"firstName", "John"}, {:ok, :last_name, "Zorn"}]
  end

  test "requires a single key" do
    assert requires([{"id", "123"}], [:id]) == [{:ok, :id, "123"}]
  end

  test "requires a single key with camel cased key" do
    params = [{"firstName", "John"}]
    assert requires(params, [:first_name]) == [{:ok, :first_name, "John"}]
  end

  test "raise a bad request error if a required key is missing" do
    assert_raise Zorn.Util.BadRequest, "missing mandatory parameter id", fn ->
      requires([{"test_id", "456"}], [:id])
    end
  end

  test "raise a bad request error if several required keys are missing" do
    assert_raise Zorn.Util.BadRequest, "missing mandatory parameters id, token", fn ->
      requires([{"test_id", "456"}], [:id, :token])
    end
  end

  test "chain requires" do
    required =
      [{"firstName", "John"}, {"lastName", "Zorn"}]
      |> requires([:first_name])
      |> requires([:last_name])
    assert required == [{:ok, :first_name, "John"}, {:ok, :last_name, "Zorn"}]
  end

  test "requiring a key doesn't make the permitted keys required" do
    specified =
      [{"account", [{"email", "test@example.com"}]}]
      |> permits(account: [:name, :email])
      # |> requires(:account)
    assert specified == [{:ok, :account, [{:ok, :email, "test@example.com"}]}]
  end

  test "allow passing an atom instead of a list of one atom to require or permit a key" do
    assert requires([{"id", "123"}], :id) == [{:ok, :id, "123"}]
    assert permits([{"test_id", "456"}], :test_id) == [{:ok, :test_id, "456"}]
  end

  test "fetch returns params marked as selected" do
    assert fetch([{:ok, :email, "john@zorn.com"}, {"admin", "1"}]) == [email: "john@zorn.com"]
  end

  test "fetch params returns only those required" do
    fetched =
      [{"account", [{"firstName", "John"}, {"lastName", "Zorn"}]}]
      |> requires([account: [:last_name]])
      |> fetch
    assert fetched == [account: [last_name: "Zorn"]]
  end

  test "fetch params for a single key" do
    fetched =
      [{"account", [{"firstName", "John"}, {"lastName", "Zorn"}]}]
      |> requires([account: [:last_name]])
      |> fetch(:account)
    assert fetched == [last_name: "Zorn"]
  end

  test "fetch params when both required and permitted" do
    fetched =
      [{"account", [{"firstName", "John"}, {"lastName", "Zorn"}, {"email", "john@zorn.com"}]}]
      |> permits([account: [:email]])
      |> requires(account: [:last_name])
      |> fetch(:account)
    assert fetched == [last_name: "Zorn", email: "john@zorn.com"]
  end

  test "underscore a 1 level camelcase dict" do
    input = [{"camelCase", "one"}, {"droMadaire", 2}]
    assert underscore(input) == [{"camel_case", "one"}, {"dro_madaire", 2}]
  end

  test "underscore a 3 levels camelcase dict" do
    input = [{"callCenter", [
      {"familyAdvisor", [{"firstName", "John"}, {"lastName", "Zorn"}]},
      {"supervisorManager", [{"firstName", "Bulle"}, {"lastName", "de Gomme"}]}
    ]}]
    assert underscore(input) == [{"call_center", [
      {"family_advisor", [{"first_name", "John"}, {"last_name", "Zorn"}]},
      {"supervisor_manager", [{"first_name", "Bulle"}, {"last_name", "de Gomme"}]}
    ]}]
  end

  test "underscore and atomify a 3 levels camelcase dict" do
    input = [{"call_center", [
      {"family_advisor", [{"first_name", "John"}, {"last_name", "Zorn"}]},
      {"supervisor_manager", [{"first_name", "Bulle"}, {"last_name", "de Gomme"}]}
    ]}]
    assert atomify(input) == [call_center: [
      family_advisor:     [first_name: "John", last_name: "Zorn"],
      supervisor_manager: [first_name: "Bulle", last_name: "de Gomme"]
    ]]
  end

  test "camelize a 1 level underscore dict" do
    input = [{"camel_case", "one"}, {"dro_madaire", 2}]
    assert camelize(input, :lower) == [{"camelCase", "one"}, {"droMadaire", 2}]
  end

  test "camelize a 3 levels underscore dict" do
    input = [{"call_center", [
      {"family_advisor", [{"first_name", "John"}, {"last_name", "Zorn"}]},
      {"supervisor_manager", [{"first_name", "Bulle"}, {"last_name", "de Gomme"}]}
    ]}]
    assert camelize(input, :lower) == [{"callCenter", [
      {"familyAdvisor", [{"firstName", "John"}, {"lastName", "Zorn"}]},
      {"supervisorManager", [{"firstName", "Bulle"}, {"lastName", "de Gomme"}]}
    ]}]
  end

  test "camelize a plain list" do
    assert camelize(["one", "two"]) == ["one", "two"]
  end
end
