defmodule OOP do
  defmacro class(class, block) do
    quote do
      defmodule unquote(class) do
        def new(fields \\ []) do
          object = :"#{unquote(class)}#{:erlang.unique_integer}"

          defmodule object do
             Module.register_attribute __MODULE__,
              :fields,
              accumulate: true, persist: false

            unquote(block)

            defstruct @fields

            def __init__(fields) do
              invalid_fields = Keyword.keys(fields) -- @fields
              for field <- invalid_fields do
                raise ArgumentError, "unknown field #{inspect(field)}"
              end

              {:ok, _pid} = Agent.start_link(fn -> struct(__MODULE__, fields) end, name: __MODULE__)
            end

            def class do
              unquote(class)
            end

            defp this do
              __MODULE__
            end
          end

          object.__init__(fields)
          object
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
