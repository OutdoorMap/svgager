defmodule Svgager.Converter do
  @moduledoc """
  High-level API for converting SVG to various image formats.

  Provides a user-friendly interface for converting SVG content to PNG, JPG, JPEG, GIF, or WebP
  with support for resolution control, background colors, and preprocessing.
  """

  alias Svgager.Native

  @supported_formats [:png, :jpg, :jpeg, :gif, :webp]

  @doc """
  Converts SVG to the specified image format and returns binary data.

  ## Options

  - `:format` - (required) Output format. One of `:png`, `:jpg`, `:jpeg`, `:gif`, or `:webp`
  - `:width` - (optional) Output width in pixels. If only width is provided, height is calculated to maintain aspect ratio
  - `:height` - (optional) Output height in pixels. If only height is provided, width is calculated to maintain aspect ratio
  - `:background_color` - (optional) Background color as hex string (e.g., "FFFFFF" or "#FF0000"). Ignored for PNG format which uses transparency. Defaults to "FFFFFF" (white) for other formats
  - `:replacements` - (optional) Map of string replacements to apply to SVG before conversion (e.g., `%{"#000000" => "#FF0000"}`)

  When both `:width` and `:height` are provided, the output uses exact dimensions (may distort if aspect ratio doesn't match original).

  ## Returns

  - `{:ok, binary_data}` - Binary image data on success
  - `{:error, reason}` - Error message on failure

  ## Examples

      # Simple PNG conversion with transparency
      {:ok, png_data} = Svgager.Converter.convert(svg_string, format: :png, width: 800)
      File.write!("output.png", png_data)

      # JPG with background color and preprocessing
      {:ok, jpg_data} = Svgager.Converter.convert(svg_string,
        format: :jpg,
        width: 1200,
        height: 800,
        background_color: "FF0000",
        replacements: %{
          "#000000" => "#FF0000",
          "fill=\\"blue\\"" => "fill=\\"red\\""
        }
      )
      File.write!("output.jpg", jpg_data)

      # WebP maintaining aspect ratio
      {:ok, webp_data} = Svgager.Converter.convert(svg_string,
        format: :webp,
        width: 1024,
        background_color: "FFFFFF"
      )
  """
  @spec convert(String.t(), keyword()) :: {:ok, binary()} | {:error, String.t()}
  def convert(svg_string, opts \\ []) when is_binary(svg_string) do
    with :ok <- validate_opts(opts),
         {:ok, format, width, height, bg_color, replacements} <- parse_opts(opts) do
      Native.convert_svg(
        svg_string,
        format,
        width,
        height,
        bg_color,
        replacements
      )
    end
  end

  defp validate_opts(opts) do
    format = Keyword.get(opts, :format)

    cond do
      is_nil(format) ->
        {:error, "format option is required"}

      format not in @supported_formats ->
        {:error,
         "unsupported format: #{inspect(format)}. Supported formats: #{inspect(@supported_formats)}"}

      true ->
        :ok
    end
  end

  defp parse_opts(opts) do
    format = Keyword.get(opts, :format) |> Atom.to_string()
    width = Keyword.get(opts, :width)
    height = Keyword.get(opts, :height)
    bg_color = Keyword.get(opts, :background_color)
    replacements = Keyword.get(opts, :replacements, %{})

    # Validate width and height if provided
    with :ok <- validate_dimension(:width, width),
         :ok <- validate_dimension(:height, height),
         {:ok, replacements_list} <- convert_replacements(replacements) do
      {:ok, format, width, height, bg_color, replacements_list}
    end
  end

  defp validate_dimension(_key, nil), do: :ok

  defp validate_dimension(_key, value) when is_integer(value) and value > 0, do: :ok

  defp validate_dimension(key, value) do
    {:error, "#{key} must be a positive integer, got: #{inspect(value)}"}
  end

  defp convert_replacements(replacements) when is_map(replacements) do
    replacements_list =
      Enum.map(replacements, fn {search, replace} ->
        {to_string(search), to_string(replace)}
      end)

    {:ok, replacements_list}
  rescue
    _ -> {:error, "replacements must be a map of strings"}
  end

  defp convert_replacements(_), do: {:error, "replacements must be a map"}
end
