defmodule OOPTest do
  use ExUnit.Case
  import OOP

  test "define empty class" do
    c = class Person do
    end

    assert c
    purge Person
  end

  test "instantiate empty object" do
    class Person do
    end

    alice = Person.new
    assert alice.class == Person
    purge Person
  end

  defp purge(module) when is_atom(module) do
    :code.delete(module)
    :code.purge(module)
  end
  defp purge(modules) when is_list(modules) do
    Enum.each(modules, &purge/1)
  end
end
