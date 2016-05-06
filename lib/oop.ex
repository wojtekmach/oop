defmodule OOP do
  defmacro class(class_expr, block, _opts \\ []) do
    quote do
      defmodule unquote(class_expr) do
        def new(data \\ []) do
          object = :"#{unquote(class_expr)}#{:erlang.unique_integer()}"

          defmodule object do
            def class do
              unquote(class_expr)
            end

            unquote(block)
          end

          object
        end
      end
    end
  end
end
