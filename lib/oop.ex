defmodule OOP do
  defmacro class(class_expr, block, _opts \\ []) do
    quote do
      defmodule unquote(class_expr) do
        unquote(block)
      end
    end
  end
end
