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

  test "define fields" do
    class Person do
      var :name

      def title(prefix) do
        "#{prefix} #{this.name}"
      end
    end

    alice = Person.new
    assert alice.name == nil

    bob = Person.new(name: "Bob")
    assert bob.name == "Bob"
    bob.set_name("Hipster Bob")
    assert bob.name == "Hipster Bob"
    assert bob.title("Mr.") == "Mr. Hipster Bob"

    assert alice.name == nil

    purge Person
  end

  test "define private fields" do
    class AppleInc do
      private_var :registered_devices

      def registered_devices_count do
        length(this.registered_devices)
      end
    end

    apple = AppleInc.new(registered_devices: ["Alice's iPhone", "Bob's iPhone"])

    assert_raise RuntimeError, fn ->
      apple.registered_devices
    end

    assert apple.registered_devices_count == 2

    purge AppleInc
  end

  test "inheritance" do
    class Animal do
      var :name

      def title(prefix) do
        "#{prefix} #{this.name}"
      end
    end

    class Dog < Animal do
      var :breed
    end

    snuffles = Dog.new(name: "Snuffles", breed: "Shih Tzu")
    assert snuffles.name == "Snuffles"
    assert snuffles.breed == "Shih Tzu"
    assert snuffles.title("Mr.") == "Mr. Snuffles"

    purge [Animal, Dog]
  end

  defp purge(module) when is_atom(module) do
    :code.delete(module)
    :code.purge(module)
  end
  defp purge(modules) when is_list(modules) do
    Enum.each(modules, &purge/1)
  end
end
