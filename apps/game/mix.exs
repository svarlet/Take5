defmodule Game.Mixfile do
  use Mix.Project

  def project do
    [app: :game,
     version: "0.1.0",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.5",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),

     # For ex_doc
     name: "Take5 game logic and models",
     source_url: "https://github.com/svarlet/Take5/tree/master/apps/game",
     homepage_url: "https://github.com/svarlet/Take5"
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # To depend on another app inside the umbrella:
  #
  #   {:my_app, in_umbrella: true}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:dialyze, "~> 0.2.1", only: [:dev, :test], runtime: false},
     {:credo, "~> 0.8", only: :dev, runtime: false},
     {:propcheck, "~> 0.0.1", only: :test},
     {:ex_doc, "~> 0.16", only: :dev, runtime: false},
     {:exceptional, "~> 2.1"}
    ]
  end
end
