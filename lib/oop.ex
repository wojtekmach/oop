defmodule OOP do
  defmacro class(class_expr, block, _opts \\ []) do
    {class, superclass} =
      case class_expr do
        {:<, _, [class, superclass]} ->
          {class, superclass}
        class ->
          {class, nil}
      end

    quote do
      defmodule unquote(class) do
        def new(data \\ []) do
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

            unquote(block)

            if unquote(superclass) do
              @parent unquote(superclass).new(data)

              for {method, arity} <- @parent.methods do
                Code.eval_quoted(inherit_method(method, arity, @parent), [], __ENV__)
              end
            end
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

  def inherit_method(method, arity, parent) do
    args = (0..arity) |> Enum.drop(1) |> Enum.map(fn i -> {:"arg#{i}", [], OOP} end)

    {:defdelegate, [context: OOP, import: Kernel],
      [{method, [], args}, [to: parent]]}
  end
end
