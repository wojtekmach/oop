defmodule OOP do
  use Application

  defmodule CodeServer do
    def start_link do
      Agent.start_link(fn -> %{} end, name: __MODULE__)
    end

    def put(class_name, code) do
      Agent.update(__MODULE__, fn map -> Map.put(map, class_name, code) end)
    end

    def get(class_name) do
      Agent.get(__MODULE__, fn map -> Map.fetch!(map, class_name) end)
    end
  end

  def start(_type, _args) do
    CodeServer.start_link
  end

  defmacro class(class_expr, block) do
    {class, superclass} = case class_expr do
      {:<, _, [class, superclass]} ->
        {class, superclass}

      class ->
        {class, nil}
    end

    {_, _, [class_name]} = class
    CodeServer.put(class_name, block)

    superclass_block = if superclass do
      {_, _, [superclass_name]} = superclass
      CodeServer.get(superclass_name)
    end


    quote do
      defmodule unquote(class) do
        def new(fields \\ []) do
          object = :"#{unquote(class)}#{:erlang.unique_integer}"

          defmodule object do
             Module.register_attribute __MODULE__,
              :fields,
              accumulate: true, persist: false

            unquote(block)
            unquote(superclass_block)

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
