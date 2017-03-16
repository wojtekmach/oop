defmodule OOP.Registry do
  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def register(pid, class) do
    Agent.update(__MODULE__, fn map -> Map.put(map, pid, class) end)
  end

  def get(pid) do
    Agent.get(__MODULE__, fn map -> Map.get(map, pid, nil) end)
  end
end

defmodule OOP.Application do
  use Application

  def start(_type, _args) do
    OOP.Registry.start_link()
  end
end

defmodule OOP.Builder do
  def create_class(class, superclasses, block, opts) do
    quote do
      defmodule unquote(class) do
        OOP.Builder.ensure_can_be_subclassed(unquote(superclasses))

        @final Keyword.get(unquote(opts), :final, false)

        def __final__? do
          @final
        end

        def new(data \\ [], descendant? \\ false) do
          OOP.Builder.ensure_can_be_instantiated(unquote(class), descendant?, unquote(opts))


          object = :"#{unquote(class)}#{:erlang.unique_integer()}"

          defmodule object do
            use GenServer

            def start_link(data) do
              GenServer.start_link(__MODULE__, data, name: __MODULE__)
            end

            def class do
              unquote(class)
            end

            def methods do
              built_ins = [
                code_change: 3, handle_call: 3, handle_cast: 2, handle_info: 2,
                init: 1, start_link: 1, terminate: 2,
                class: 0, methods: 0,
              ]

              __MODULE__.__info__(:functions) -- built_ins
            end

            import Kernel, except: [def: 2]

            Module.register_attribute(__MODULE__, :friends, accumulate: true)

            unquote(block)

            Enum.each(unquote(superclasses), fn superclass ->
              parent = superclass.new(data, true)

              for {method, arity} <- parent.methods do
                Code.eval_quoted(OOP.Builder.inherit_method(method, arity, parent), [], __ENV__)
              end
            end)
          end

          {:ok, pid} = object.start_link(Enum.into(data, %{}))
          OOP.Registry.register(pid, unquote(class))

          object
        end
      end
    end
  end

  def ensure_can_be_subclassed(superclasses) do
    Enum.each(superclasses, fn s ->
      if s.__final__?, do: raise "cannot subclass final class #{s}"
    end)
  end

  def ensure_can_be_instantiated(class, descendant?, opts) do
    abstract? = Keyword.get(opts, :abstract, false)

    if !descendant? and abstract? do
      raise "cannot instantiate abstract class #{class}"
    end
  end

  def create_method(call, expr) do
    # HACK: this is a really gross way of checking if the function is using `this`.
    #       if so, we let it leak: `var!(this) = data`.
    #       We do this so that we don't get the "unused variable this" warning when
    #       we don't use `this`.
    using_this? = String.match?(Macro.to_string(expr), ~r"\bthis\.")

    {method, args} = Macro.decompose_call(call)

    handle_call_quoted =
      quote do
        try do
          [do: value] = unquote(expr)
          {:reply, {:ok, value}, data}
        rescue
          e in [RuntimeError] ->
            {:reply, {:error, e}, data}
        end
      end

    quote do
      def unquote(call) do
        case GenServer.call(__MODULE__, {:call, unquote(method), unquote(args)}) do
          {:ok, value} -> value
          {:error, e} -> raise e
        end
      end

      if unquote(using_this?) do
        def handle_call({:call, unquote(method), unquote(args)}, _from, data) do
          var!(this) = data
          unquote(handle_call_quoted)
        end
      else
        def handle_call({:call, unquote(method), unquote(args)}, _from, data) do
          unquote(handle_call_quoted)
        end
      end
    end
  end

  def inherit_method(method, arity, parent) do
    args = (0..arity) |> Enum.drop(1) |> Enum.map(fn i -> {:"arg#{i}", [], OOP} end)

    {:defdelegate, [context: OOP, import: Kernel],
      [{method, [], args}, [to: parent]]}
  end

  def create_var(field, opts) do
    private? = Keyword.get(opts, :private, false)

    quote do
      def unquote(field)() do
        case GenServer.call(__MODULE__, {:get, unquote(field)}) do
          {:ok, value} -> value
          {:error, :private} -> raise "Cannot access private var #{unquote(field)}"
        end
      end

      def unquote(:"set_#{field}")(value) do
        GenServer.call(__MODULE__, {:set, unquote(field), value})
      end

      def handle_call({:get, unquote(field)}, {pid, _ref}, data) do
        classes = [class() | @friends]
        if unquote(private?) and ! OOP.Registry.get(pid) in classes do
          {:reply, {:error, :private}, data}
        else
          {:reply, {:ok, Map.get(data, unquote(field))}, data}
        end
      end

      def handle_call({:set, unquote(field), value}, _from, data) do
        {:reply, value, Map.put(data, unquote(field), value)}
      end
    end
  end
end

defmodule OOP do
  defmacro class(class_expr, block, opts \\ []) do
    {class, superclasses} =
      case class_expr do
        {:<, _, [class, superclasses]} when is_list(superclasses) ->
          {class, superclasses}

        {:<, _, [class, superclass]} ->
          {class, [superclass]}

        class ->
          {class, []}
      end

    OOP.Builder.create_class(class, superclasses, block, opts)
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

  defmacro def(call, expr \\ nil) do
    OOP.Builder.create_method(call, expr)
  end

  defmacro var(field, opts \\ []) do
    OOP.Builder.create_var(field, opts)
  end

  defmacro private_var(field) do
    quote do
      var(unquote(field), private: true)
    end
  end

  defmacro friend(class) do
    quote do
      @friends unquote(class)
    end
  end
end
