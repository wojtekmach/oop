defmodule OOP.Mixfile do
  use Mix.Project

  def project do
    [app: :oop,
     version: "0.0.4",
     description: "OOP in Elixir!",
     package: package,
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [mod: {OOP, []}, applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
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
