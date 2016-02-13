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
      Agent.get(object, fn data -> Map.fetch!(data, field) end)
    end

    def set(object, field, value) do
      Agent.update(object, fn data -> %{data | field => value} end)
    end
  end

  def start(_type, _args) do
    ClassServer.start_link
  end

  defmacro class(class_expr, block) do
    {class, superclasses} = case class_expr do
      {:<, _, [class, superclasses]} when is_list(superclasses) ->
        {class, superclasses}

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

    create_class(class, superclasses, block, superclass_blocks)
  end

  defp create_class(class, superclasses, block, superclass_blocks) do
    fields = extract_fields(block)
    methods = extract_methods(block)

    quote do
      defmodule unquote(class) do
        def fields do
          unquote(fields) ++ Enum.flat_map(unquote(superclasses), fn s -> s.fields end)
        end

        def methods do
          unquote(methods)
        end

        def new(fields \\ []) do
          object = :"#{unquote(class)}#{:erlang.unique_integer}"

          defmodule object do
            unquote(block)
            unquote(superclass_blocks)

            defstruct unquote(class).fields

            def __init__(fields) do
              invalid_fields = Keyword.keys(fields) -- unquote(class).fields
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

  defp extract_fields([do: nil]), do: []
  defp extract_fields([do: {:def, _, _}]), do: []
  defp extract_fields([do: {:__block__, _, declarations}]) do
    for {:var, _, [field]} <- declarations, do: field
  end
  defp extract_fields([do: {:var, _, [field]}]), do: [field]

  defp extract_methods([do: nil]), do: []
  defp extract_methods([do: {:def, _, [{name, _, arg_exprs}, _code]}]) do
    [{name, extract_arity(arg_exprs)}]
  end
  defp extract_methods([do: {:var, _, [field]}]), do: [{field, 0}, {:"set_#{field}", 1}]
  defp extract_methods([do: {:__block__, _, declarations}]) do
    methods =
      for {:def, _, [{name, _, arg_exprs}, _code]} <- declarations do
        {name, extract_arity(arg_exprs)}
      end

    field_methods =
      for {:var, _, [field]} <- declarations do
        [{field, 0}, {:"set_#{field}", 1}]
      end

    List.flatten(field_methods) ++ methods
  end

  defp extract_arity(nil), do: 0
  defp extract_arity(exprs), do: length(exprs)

  defmacro var(field) do
    quote do
      def unquote(field)() do
        ObjectServer.get(__MODULE__, unquote(field))
      end

      def unquote(:"set_#{field}")(value) do
        ObjectServer.set(__MODULE__, unquote(field), value)
      end
    end
  end
end
