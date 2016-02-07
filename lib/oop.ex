defmodule OOP do
  defmacro class(name, contents) do
    quote do
      defmodule unquote(name) do
        def new(fields \\ []) do
          module = :"#{unquote(name)}#{:erlang.unique_integer}"

          defmodule module do
             Module.register_attribute __MODULE__,
              :fields,
              accumulate: true, persist: false

            def class do
              unquote(name)
            end

            unquote(contents)

            defstruct @fields

            def __init__(fields) do
              invalid_fields = Keyword.keys(fields) -- @fields
              for field <- invalid_fields do
                raise ArgumentError, "unknown field #{inspect(field)}"
              end

              {:ok, _pid} = Agent.start_link(fn -> struct(__MODULE__, fields) end, name: __MODULE__)
            end

            defp this do
              __MODULE__
            end
          end

          module.__init__(fields)
          module
        end
      end
    end
  end

  defmacro var(field) do
    quote do
      @fields unquote(field)

      def unquote(field)() do
        Agent.get(__MODULE__, fn data -> Map.get(data, unquote(field)) end)
      end

      def unquote(:"set_#{field}")(value) do
        Agent.update(__MODULE__, fn data -> Map.update!(data, unquote(field), fn _ -> value end) end)
      end
    end
  end
end
