defmodule OOP do
  defmacro class(class_expr, block, _opts \\ []) do
    block = transform(block)

    quote do
      defmodule unquote(class_expr) do
        def new(data \\ []) do
          object = :"#{unquote(class_expr)}#{:erlang.unique_integer()}"

          defmodule object do
            use GenServer

            def start_link(data) do
              GenServer.start_link(__MODULE__, data, name: __MODULE__)
            end

            def class do
              unquote(class_expr)
            end

            unquote(block)
          end

          {:ok, pid} = object.start_link(Enum.into(data, %{}))

          object
        end
      end
    end
  end

  defp transform(do: nil) do
    nil
  end
  defp transform(do: {:__block__, _, defs}) do
    Enum.map(defs, &transform(do: &1))
  end
  defp transform(do: {:def, _, [{method_name, _, args}, [do: block]]}) do
		callback_args = transform_args(args)

    [
      {:def, [context: Elixir, import: Kernel],
			 [{method_name, [context: Elixir], callback_args},
				[do: {{:., [], [{:__aliases__, [alias: false], [:GenServer]}, :call]}, [],
					[{:__MODULE__, [], Elixir},
					 {:{}, [], [method_name | callback_args]}]}]]},

      {:def, [context: Elixir, import: Kernel],
       [{:handle_call, [context: Elixir],
         [{:{}, [], [method_name | callback_args]}, {:_from, [], Elixir},
          {:data, [], Elixir}]},
        [do: {:{}, [],
          [:reply, {:"_#{method_name}", [], callback_args},
           {:data, [], Elixir}]}]]},

		  {:defp, [], [{:"_#{method_name}", [], args}, [do: block]]},
    ]
  end
  defp transform(do: {:var, _, [name]}) do
    quote do
      def unquote(name)() do
        GenServer.call(__MODULE__, {:get, unquote(name)})
      end

      def unquote(:"set_#{name}")(value) do
        GenServer.call(__MODULE__, {:set, unquote(name), value})
      end

      def handle_call({:get, unquote(name)}, _from, data) do
        value = Map.get(data, unquote(name))
        {:reply, value, data}
      end

      def handle_call({:set, field, value}, _from, data) do
        data = %{data | field => value}
        {:reply, value, data}
      end
    end
  end

  defp transform_args(nil), do: []
  defp transform_args(args) when is_list(args) do
		Enum.map(args, fn {arg, line, nil} -> {arg, line, Elixir} end)
  end
end
