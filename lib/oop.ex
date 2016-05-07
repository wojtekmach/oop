defmodule OOP do
  defmacro class(class_expr, block, _opts \\ []) do
    quote do
      defmodule unquote(class_expr) do
        def new(data \\ []) do
          object = :"#{unquote(class_expr)}#{:erlang.unique_integer()}"

          defmodule object do
            use GenServer

            def start_link(data) do
              GenServer.start_link(__MODULE__, data, name: __MODULE__)
            end

            def class do
              unquote(class_expr)
            end

            unquote(block)
          end

          {:ok, pid} = object.start_link(Enum.into(data, %{}))

          object
        end
      end
    end
  end

  defmacro var(field) do
    quote do
      def unquote(field)() do
        GenServer.call(__MODULE__, {:get, unquote(field)})
      end

      def unquote(:"set_#{field}")(value) do
        GenServer.call(__MODULE__, {:set, unquote(field), value})
      end

      def handle_call({:get, unquote(field)}, _from, data) do
        {:reply, Map.get(data, unquote(field)), data}
      end

      def handle_call({:set, unquote(field), value}, _from, data) do
        {:reply, value, Map.put(data, unquote(field), value)}
      end
    end
  end
end
