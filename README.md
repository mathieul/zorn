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

Fetch dependencies and initialize the project for Zorn:

```bash
$ mix do deps.get, compile
$ mix zorn.init
```

And follow the instructions :)
