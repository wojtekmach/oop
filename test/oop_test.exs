defmodule OOPTest do
  use ExUnit.Case

  test "define empty class" do
    import OOP
    c = class Person1 do
    end

    assert c == Person1
  end

  test "instantiate empty object" do
    import OOP
    class Person2 do
    end

    alice = Person2.new
    assert alice.class == Person2
  end
end
