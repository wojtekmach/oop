defmodule OOP do
  use Application

  defmodule ClassServer do
    def start_link do
      Agent.start_link(fn -> %{} end, name: __MODULE__)
    end

    def get(class_name) do
      Agent.get(__MODULE__, fn map -> Map.fetch!(map, class_name) end)
    end

    def set(class_name, code) do
      Agent.update(__MODULE__, fn map -> Map.put(map, class_name, code) end)
    end
  end

  defmodule ObjectServer do
    def start_link(object, fields) do
      Agent.start_link(fn -> struct(object, fields) end, name: object)
    end

    def get(object, field) do
      Agent.get(object, fn data -> Map.get(data, field) end)
    end

    def set(object, field, value) do
      Agent.update(object, fn data -> Map.update!(data, field, fn _ -> value end) end)
    end
  end

  def start(_type, _args) do
    ClassServer.start_link
  end

  defmacro class(class_expr, block) do
    {class, superclasses} = case class_expr do
      {:<, _, [class, [h | t]]} ->
        {class, [h] ++ t}

      {:<, _, [class, superclass]} ->
        {class, [superclass]}

      class ->
        {class, []}
    end

    {_, _, [class_name]} = class
    ClassServer.set(class_name, block)

    superclass_blocks = Enum.map(superclasses, fn superclass ->
      {_, _, [superclass_name]} = superclass
      ClassServer.get(superclass_name)
    end)

    quote do
      defmodule unquote(class) do
        def new(fields \\ []) do
          object = :"#{unquote(class)}#{:erlang.unique_integer}"

          defmodule object do
             Module.register_attribute __MODULE__,
              :fields,
              accumulate: true, persist: false

            unquote(block)
            unquote(superclass_blocks)

            defstruct @fields

            def __init__(fields) do
              invalid_fields = Keyword.keys(fields) -- @fields
              for field <- invalid_fields do
                raise ArgumentError, "unknown field #{inspect(field)}"
              end

              {:ok, _pid} = ObjectServer.start_link(__MODULE__, fields)
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
        ObjectServer.get(__MODULE__, unquote(field))
      end

      def unquote(:"set_#{field}")(value) do
        ObjectServer.set(__MODULE__, unquote(field), value)
      end
    end
  end
end
