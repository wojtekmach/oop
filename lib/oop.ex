defmodule OOP do
  defmacro var(field) do
    quote do
      def unquote(field)() do
        Agent.get(__MODULE__, fn data -> data[unquote(field)] end)
      end

      def unquote(:"set_#{field}")(value) do
        Agent.update(__MODULE__, fn data -> Map.merge(data, %{unquote(field) => value}) end)
      end
    end
  end

  defmacro class(name, contents) do
    quote do
      defmodule unquote(name) do
        def new do
          module_name = :"#{unquote(name)}#{:erlang.unique_integer}"

          defmodule module_name do
            def class do
              unquote(name)
            end

            unquote(contents)
          end

          {:ok, _pid} = Agent.start_link(fn -> %{} end, name: module_name)

          module_name
        end
      end
    end
  end
end
