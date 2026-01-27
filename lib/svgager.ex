defmodule Svgager do
  @moduledoc """
  SVG to image conversion library using Rustler.

  Svgager provides high-performance SVG to image conversion with support for multiple
  output formats (PNG, JPG, JPEG, GIF, WebP), resolution control, background colors,
  and SVG preprocessing.

  ## Features

  - Convert SVG to PNG, JPG, JPEG, GIF, or WebP
  - Control output resolution (width, height, or both)
  - Automatic aspect ratio preservation when one dimension is provided
  - Transparent backgrounds for PNG, configurable backgrounds for other formats
  - Preprocess SVG content with string replacements (useful for color changes)

  ## Examples

      # Convert SVG to PNG with transparency
      svg = File.read!("input.svg")
      {:ok, png_data} = Svgager.convert(svg, format: :png, width: 800)
      File.write!("output.png", png_data)

      # Convert to JPG with red background
      {:ok, jpg_data} = Svgager.convert(svg,
        format: :jpg,
        width: 1200,
        height: 800,
        background_color: "FF0000"
      )

      # Preprocess SVG to change colors before conversion
      {:ok, webp_data} = Svgager.convert(svg,
        format: :webp,
        width: 1024,
        replacements: %{
          "#000000" => "#FF5500",
          "blue" => "red"
        }
      )
  """

  alias Svgager.Converter

  @doc """
  Converts SVG to the specified image format and returns binary data.

  This is the main entry point for the library. See `Svgager.Converter.convert/2`
  for detailed documentation.

  ## Options

  - `:format` - (required) Output format (`:png`, `:jpg`, `:jpeg`, `:gif`, or `:webp`)
  - `:width` - (optional) Output width in pixels
  - `:height` - (optional) Output height in pixels
  - `:background_color` - (optional) Background color as hex string (ignored for PNG)
  - `:replacements` - (optional) Map of string replacements for preprocessing

  ## Returns

  - `{:ok, binary_data}` - Binary image data on success
  - `{:error, reason}` - Error message on failure
  """
  @spec convert(String.t(), keyword()) :: {:ok, binary()} | {:error, String.t()}
  defdelegate convert(svg_string, opts \\ []), to: Converter
end
