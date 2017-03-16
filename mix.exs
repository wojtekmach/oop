defmodule OOP.Mixfile do
  use Mix.Project

  def project do
    [app: :oop,
     version: "0.1.1",
     description: "OOP in Elixir!",
     package: package(),
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [mod: {OOP.Application, []}]
  end

  defp deps do
    []
  end

  defp package do
    [
      maintainers: ["Wojtek Mach"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/wojtekmach/oop"},
    ]
  end
end
