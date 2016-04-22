defmodule OOPTest do
  use ExUnit.Case
  import OOP

  test "all features" do
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
    purge Person
  end

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
      def the_answer do
        42
      end
    end

    alice = Person.new
    assert alice.the_answer == 42
    purge Person
  end

  test "define fields on objects" do
    class Person do
      var :name
    end

    alice = Person.new
    assert alice.name == nil
    purge Person
  end

  test "set field values" do
    class Person do
      var :name
    end

    alice = Person.new
    assert alice.name == nil
    alice.set_name("Alice")
    assert alice.name == "Alice"
    purge Person
  end

  test "instantiate objects with fields" do
    class Person do
      var :name
    end

    alice = Person.new(name: "Alice")
    assert alice.name == "Alice"

    assert_raise ArgumentError, "unknown field :invalid_field", fn ->
      Person.new(invalid_field: "Bob")
    end
    purge Person
  end

  test "this" do
    class Person do
      var :name

      def shout do
        String.upcase(this.name)
      end
    end

    alice = Person.new(name: "Alice")
    assert alice.shout == "ALICE"
    purge Person
  end

  test "multiple objects" do
    class Person do
      var :name
    end

    alice = Person.new
    alice.set_name("Alice")

    bob = Person.new
    bob.set_name("Bob")

    assert alice.name == "Alice"
    assert bob.name == "Bob"
    purge Person
  end

  test "inheritance" do
    class Animal do
      var :name

      def title(prefix) do
        "#{prefix} #{name}"
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

  test "multiple inheritance" do
    class Human do
      var :name
    end

    class Horse do
      var :horseshoes_on?
    end

    class Centaur < [Human, Horse] do
    end

    john = Centaur.new(name: "John", horseshoes_on?: true)
    assert john.name == "John"
    assert john.horseshoes_on? == true

    purge [Human, Horse, Centaur]
  end

  test "define abstract class" do
    abstract class ActiveRecord.Base do
    end

    assert_raise RuntimeError, "cannot instantiate abstract class #{ActiveRecord.Base}", fn ->
      ActiveRecord.Base.new
    end

    class Post < ActiveRecord.Base do
      var :title
    end

    assert Post.new(title: "Post 1").title == "Post 1"
    purge [ActiveRecord.Base, Post]
  end

  test "abstract class inheriting from abstract class" do
    abstract class ActiveRecord.Base do
    end

    abstract class ApplicationRecord < ActiveRecord.Base do
    end

    assert_raise RuntimeError, "cannot instantiate abstract class #{ActiveRecord.Base}", fn ->
      ActiveRecord.Base.new
    end

    assert_raise RuntimeError, "cannot instantiate abstract class #{ApplicationRecord}", fn ->
      ApplicationRecord.new
    end

    class Post < ApplicationRecord do
      var :title
    end

    assert Post.new(title: "Post 1").title == "Post 1"
    purge [ActiveRecord.Base, ApplicationRecord, Post]
  end

  test "define final class" do
    final class FriezaForthForm do
    end

    assert FriezaForthForm.new

    assert_raise RuntimeError, "cannot subclass final class #{FriezaForthForm}", fn ->
      class FriezaFifthForm < FriezaForthForm do
      end
    end
  end

  test "define private fields" do
    class AppleInc do
      private_var :registered_devices

      def registered_devices_count do
        length(registered_devices)
      end
    end

    apple = AppleInc.new(registered_devices: ["Alice's iPhone", "Bob's iPhone"])

    assert_raise UndefinedFunctionError, fn ->
      apple.registered_devices
    end

    assert apple.registered_devices_count == 2
  end

  test "returns fields defined on a class" do
    class Empty do
    end

    class JustMethod do
      def foo do
      end
    end

    class JustMethods do
      def foo do
      end

      def bar do
      end
    end

    class JustField do
      var :foo
    end

    class JustFields do
      var :foo
      var :bar
    end

    class JustPrivateField do
      private_var :foo
    end

    class JustPrivateFields do
      private_var :foo
      private_var :bar
    end

    class FieldsAndMethods do
      var :foo

      def bar do
      end
    end

    assert Empty.fields == []
    assert JustMethod.fields == []
    assert JustMethods.fields == []
    assert JustField.fields == [:foo]
    assert JustFields.fields == [:foo, :bar]
    assert JustPrivateField.fields == [:foo]
    assert JustPrivateFields.fields == [:foo, :bar]
    assert FieldsAndMethods.fields == [:foo]

    purge [Empty, JustMethod, JustMethods, JustField, JustFields, JustPrivateField, JustPrivateFields, FieldsAndMethods]
  end

  test "returns methods defined on a class" do
    class Empty do
    end

    class JustMethod do
      def foo do
      end
    end

    class JustMethodWithArity do
      def foo(_arg1, _arg2) do
      end
    end

    class JustMethodsWithArities do
      def foo do
      end

      def bar(_arg1) do
      end

      def baz(_arg1, _arg2) do
      end
    end

    class JustFields do
      var :foo
    end

    class FieldsAndMethods do
      var :foo

      def bar(_arg1) do
      end
    end

    assert Empty.methods == []
    assert JustMethod.methods == [foo: 0]
    assert JustMethodWithArity.methods == [foo: 2]
    assert JustMethodsWithArities.methods == [foo: 0, bar: 1, baz: 2]
    assert JustFields.methods == [foo: 0, set_foo: 1]
    assert FieldsAndMethods.methods == [foo: 0, set_foo: 1, bar: 1]

    purge [Empty, JustMethod, JustMethod, JustMethodWirthArity, JustMethodsWithArities, JustFields, FieldsAndMethods]
  end

  test "define static methods" do
    class Main do
      static def main(args) do
        {:ok, args}
      end
    end

    assert Main.main([:foo, :bar]) == {:ok, [:foo, :bar]}
  end

  defp purge(module) when is_atom(module) do
    :code.delete(module)
    :code.purge(module)
  end
  defp purge(modules) when is_list(modules) do
    Enum.each(modules, &purge/1)
  end
end
