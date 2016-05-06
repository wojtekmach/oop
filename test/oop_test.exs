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

  test "define methods on objects" do
    class Person do
      def zero do
        0
      end

      def sum1(a) do
        a
      end

      def sum2(a, b) do
        a + b
      end
    end

    alice = Person.new
    assert alice.zero() == 0
    assert alice.sum1(1) == 1
    assert alice.sum2(1, 2) == 3
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
