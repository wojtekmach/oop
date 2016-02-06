defmodule OOP do
  defmacro var(field) do
    quote do
      def unquote(field)() do
        GenServer.call(__MODULE__, {:get, unquote(field)})
      end

      def unquote(:"set_#{field}")(new_value) do
        GenServer.cast(__MODULE__, {:set, unquote(field), new_value})
      end

      def handle_call({:get, unquote(field)}, _from, data) do
        {:reply, data[unquote(field)], data}
      end

      def handle_cast({:set, unquote(field), value}, data) do
        new_data = Map.merge(data, %{unquote(field) => value})
        {:noreply, new_data}
      end
    end
  end

  defmacro class(name, contents) do
    quote do
      defmodule unquote(name) do
        def new do
          module_name = :"#{unquote(name)}#{:erlang.unique_integer}"

          defmodule module_name do
            use GenServer

            def class do
              unquote(name)
            end

            unquote(contents)
          end

          {:ok, pid} = GenServer.start_link(module_name, %{}, name: module_name)

          module_name
        end
      end
    end
  end
end
