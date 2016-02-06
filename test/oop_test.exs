defmodule OOPTest do
  use ExUnit.Case

  test "all features" do
    import OOP

    class Person do
      var :name
      var :date_of_birth

      def age do
        {{current_year, _, _}, _} = :calendar.local_time()
        {year, _, _} = date_of_birth

        current_year - year
      end
    end

    alice = Person.new
    alice.set_name("Alice")
    assert alice.name == "Alice"

    alice.set_date_of_birth({1970, 1, 1})
    assert alice.date_of_birth == {1970, 1, 1}
    assert alice.age == 46 # as of 2016
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

  test "multiple objects" do
    import OOP
    class Person6 do
      var :name
    end

    alice = Person6.new
    alice.set_name("Alice")

    bob = Person6.new
    bob.set_name("Bob")

    assert alice.name == "Alice"
    assert bob.name == "Bob"
  end
end
