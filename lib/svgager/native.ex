defmodule Svgager.Native do
  @moduledoc """
  Native Implemented Functions (NIFs) for SVG conversion using Rustler.
  """

  version = Mix.Project.config()[:version]

  # Read force_build setting from config
  # Can be overridden with SVGAGER_BUILD environment variable
  force_build? =
    System.get_env("SVGAGER_BUILD") in ["1", "true"] ||
      Application.compile_env(:svgager, :force_build_nif, false)

  use RustlerPrecompiled,
    otp_app: :svgager,
    crate: "svgager_native",
    base_url: "https://github.com/OutdoorMap/svgager/releases/download/v#{version}",
    force_build: force_build?,
    version: version

  @doc """
  Converts SVG data to image format.

  This function is implemented in Rust and loaded as a NIF.

  ## Parameters
  - `svg_data`: SVG content as a string
  - `format`: Output format ("png", "jpg", "jpeg", "gif", "webp")
  - `width`: Optional output width (maintains aspect ratio if height is nil)
  - `height`: Optional output height (maintains aspect ratio if width is nil)
  - `background_color`: Optional hex color string for non-PNG formats (e.g., "FFFFFF")
  - `replacements`: List of {search, replace} tuples for preprocessing SVG content

  ## Returns
  - `{:ok, binary}` on success
  - `{:error, reason}` on failure
  """
  def convert_svg(_svg_data, _format, _width, _height, _background_color, _replacements),
    do: :erlang.nif_error(:nif_not_loaded)
end
