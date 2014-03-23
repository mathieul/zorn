# Zorn #

Library to help building web applications using an Elixir web backend and
a JavaScript MVC client framework.

## Installation ##

Create a new mix project:

```bash
$ mix new tutorial
$ cd tutorial
```

Edit `mix.exs` and replace `deps` with:

```elixir
defp deps do
  [{:zorn, github: "mathieul/zorn"}]
end
```

Fetch dependencies and setup the project for an Ember.js application:

```bash
$ mix do deps.get, compile
$ mix zorn.gen.emberapp
```

And follow the instructions :)
