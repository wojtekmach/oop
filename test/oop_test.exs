defmodule OOPTest do
  use ExUnit.Case

  test "all features" do
    import OOP

    class Person do
      var :first_name
      var :last_name

      def name do
        "#{first_name} #{last_name}"
      end
    end

    john = Person.new(first_name: "John")
    assert john.first_name == "John"
    assert john.last_name == nil

    john.set_last_name("Doe")
    assert john.last_name == "Doe"

    assert john.name == "John Doe"
  end

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

  test "set field values" do
    import OOP
    class Person5 do
      var :name
    end

    alice = Person5.new
    assert alice.name == nil
    alice.set_name("Alice")
    assert alice.name == "Alice"
  end

  test "instantiate objects with fields" do
    import OOP
    class Person6 do
      var :name
    end

    alice = Person6.new(name: "Alice")
    assert alice.name == "Alice"

    assert_raise ArgumentError, "unknown field :invalid_field", fn ->
      Person6.new(invalid_field: "Bob")
    end
  end

  test "this" do
    import OOP
    class Person7 do
      var :name

      def shout do
        String.upcase(this.name)
      end
    end

    alice = Person7.new(name: "Alice")
    assert alice.shout == "ALICE"
  end

  test "multiple objects" do
    import OOP
    class Person8 do
      var :name
    end

    alice = Person8.new
    alice.set_name("Alice")

    bob = Person8.new
    bob.set_name("Bob")

    assert alice.name == "Alice"
    assert bob.name == "Bob"
  end
end
