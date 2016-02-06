defmodule OOPTest do
  use ExUnit.Case

  test "define empty class" do
    import OOP

    c = class Person do
    end

    assert c == Person
  end
end
