defmodule Wordler.MixProject do
  use Mix.Project

  @version "0.1.1"
  @url "https://github.com/j4p3/wordler"
  @docs "https://hexdocs.pm/wordler/"
  @name "Wordler"

  def project do
    [
      app: :wordler,
      version: @version,
      name: @name,
      package: package(),
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [description: "Qrono API wrapper",
     files: ["lib", "config", "mix.exs", "README*"],
     maintainers: ["JP Bonner"],
     licenses: ["MIT"],
     links: %{github: @url, docs: @docs},
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
