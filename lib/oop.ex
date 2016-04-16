defmodule OOP do
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

  defmacro class(class_expr, block, opts \\ []) do
    {class, superclasses} = case class_expr do
      {:<, _, [class, superclasses]} when is_list(superclasses) ->
        {class, superclasses}

      {:<, _, [class, superclass]} ->
        {class, [superclass]}

      class ->
        {class, []}
    end

    create_class(class, superclasses, block, opts)
  end

  defmacro abstract(class_expr, block) do
    {:class, _, [class]} = class_expr

    quote do
      OOP.class(unquote(class), unquote(block), abstract: true)
    end
  end

  defmacro final(class_expr, block) do
    {:class, _, [class]} = class_expr

    quote do
      OOP.class(unquote(class), unquote(block), final: true)
    end
  end

  defp create_class(class, superclasses, block, opts) do
    fields = extract_fields(block)
    methods = extract_methods(block)
    abstract? = Keyword.get(opts, :abstract, false)

    quote do
      defmodule unquote(class) do

        Enum.each(unquote(superclasses), fn s ->
          if s.__final__? do
            raise "cannot subclass final class #{s}"
          end
        end)

        @final Keyword.get(unquote(opts), :final, false)

        def __final__? do
          @final
        end

        def fields do
          unquote(fields) ++ Enum.flat_map(unquote(superclasses), fn s -> s.fields end)
        end

        def methods do
          unquote(methods)
        end

        def new(fields \\ [], descendant? \\ false) do
          if !descendant? && unquote(abstract?) do
            raise "cannot instantiate abstract class #{unquote(class)}"
          end

          object = :"#{unquote(class)}#{:erlang.unique_integer}"
          superclass_fields = Enum.flat_map(unquote(superclasses), fn s -> s.fields end)

          defmodule object do
            unquote(block)

            for superclass <- unquote(superclasses) do
              parent = superclass.new(Enum.filter(fields, fn {field, _} -> field in superclass.fields end), true)

              for {method, arity} <- superclass.methods do
                Code.eval_quoted(delegated_method_quoted(parent, method, arity), [], __ENV__)
              end
            end

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

  def delegated_method_quoted(parent, method, arity) do
    args =
      if arity > 0 do
        (0..arity) |> Enum.drop(1) |> Enum.map(fn i -> {:"arg#{i}", [], OOP} end)
      else
        []
      end

    {:defdelegate, [context: OOP, import: Kernel],
      [{method, [], args},
        [to: parent]]}
  end
end
