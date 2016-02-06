defmodule OOP do
  def class(name, _body) do
    contents =
      quote do
        def new do
          %{class: unquote(name)}
        end
      end

    Module.create(name, contents, Macro.Env.location(__ENV__))
    name
  end
end
