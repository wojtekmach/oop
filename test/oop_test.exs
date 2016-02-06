defmodule OOPTest do
  use ExUnit.Case

  test "define empty class" do
    import OOP
    c = class Person1 do
    end

    assert c
  end

  test "instantiate empty object" do
    import OOP
    class Person2 do
    end

    alice = Person2.new
    assert alice.class == Person2
  end

  test "define methods on objects" do
    import OOP
    class Person3 do
      def the_answer do
        42
      end
    end

    alice = Person3.new
    assert alice.the_answer == 42
  end

  test "define fields on objects" do
    import OOP
    class Person4 do
      var :name
    end

    alice = Person4.new
    assert alice.name == nil
  end
end
