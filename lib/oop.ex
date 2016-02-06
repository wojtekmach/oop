defmodule OOP do
  defmacro class(name, contents) do
    quote do
      defmodule unquote(name) do
        def new do
          defmodule Object do
            def class do
              unquote(name)
            end

            unquote(contents)
          end
          Object
        end
      end
    end
  end
end
