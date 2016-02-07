# OOP

Are you tired of all of that modules, processes and functions nonsense? Do you want to just use classes, objects and methods? If so, use OOP [1] library in Elixir [2]!

[1] Actually, according to Alan Key, the inventor of OOP, "objects" is the lesser idea; the big idea is "messaging". In that sense, I can't agree more with Joe Armstrong's quote that Erlang is "possibly the only object-oriented language".

[2] Please don't. You've been warned.

## Example

```elixir
import OOP

class Person do
  var :name

  def say_hello_to(who) do
    say_to(who, "Hello #{who.name}")
  end

  def say_to(who, something) do
    who.hear_from(this, something)
  end

  def hear_from(who, what) do
    IO.puts("#{who.name}: #{what}")
  end
end

joe = Person.new(name: "Joe")
mike = Person.new(name: "Mike")
robert = Person.new(name: "Robert")

joe.say_hello_to(mike)    # Joe: Hello Mike
mike.say_hello_to(joe)    # Mike: Hello Joe
mike.say_hello_to(robert) # Mike: Hello Robert
robert.say_hello_to(mike) # Robert: Hello Mike

joe.set_name("Hipster Joe")
joe.name # => Hipster Joe

joe.say_to(robert, "I like this OOP thing") # ** (exit) "reasons"
```

An OOP library wouldn't be complete without inheritance:

```elixir
class Animal do
  var :name
end

class Dog < Animal do
  var :breed
end

snuffles = Dog.new(name: "Snuffles", breed: "Shih Tzu")
assert snuffles.name == "Snuffles"
assert snuffles.breed == "Shih Tzu"
```

... or multiple inheritance:

```elixir
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
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `oop` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:oop, "~> 0.0.1"}]
    end
    ```

  2. Ensure `oop` is started before your application:

    ```elixir
    def application do
      [applications: [:oop]]
    end
    ```

## License

The MIT License (MIT)

Copyright (c) 2015-2016 Wojciech Mach

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
