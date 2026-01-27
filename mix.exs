defmodule Svgager.MixProject do
  use Mix.Project

  def project do
    [
      app: :svgager,
      version: "0.1.0",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),

      # Hex
      description: description(),
      package: package(),
      source_url: "https://github.com/OWNER/svgager",
      homepage_url: "https://github.com/OWNER/svgager",
      docs: docs()
    ]
  end

  defp description do
    """
    High-performance SVG to image conversion library for Elixir.
    Converts SVG to PNG, JPG, GIF, or WebP with support for resolution control,
    transparent backgrounds, and dynamic color preprocessing. Powered by Rust.
    """
  end

  defp package do
    [
      name: "svgager",
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/OWNER/svgager",
        "Issues" => "https://github.com/OWNER/svgager/issues"
      },
      files: ~w(lib native/svgager_native/.cargo native/svgager_native/src
                native/svgager_native/Cargo.* .formatter.exs mix.exs README.md
                LICENSE CHANGELOG.md checksum-*.exs config)
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md", "CONTRIBUTING.md", "DEVELOPMENT.md", "LICENSE"]
    ]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Specifies which paths to compile per environment
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:rustler, "~> 0.35.0", optional: true},
      {:rustler_precompiled, "~> 0.8.0"}
    ]
  end
end
