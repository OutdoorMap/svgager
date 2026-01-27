defmodule Svgager.TestHelper do
  @moduledoc """
  Helper functions and sample data for testing.
  """

  import Bitwise

  @doc """
  Returns a simple valid SVG for testing.
  """
  def simple_svg do
    """
    <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100">
      <rect x="10" y="10" width="80" height="80" fill="#FF0000" />
    </svg>
    """
  end

  @doc """
  Returns a more complex SVG with multiple elements.
  """
  def complex_svg do
    """
    <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200" viewBox="0 0 200 200">
      <rect x="0" y="0" width="200" height="200" fill="#FFFFFF" />
      <circle cx="100" cy="100" r="50" fill="#0000FF" />
      <rect x="75" y="75" width="50" height="50" fill="#00FF00" />
      <text x="100" y="180" text-anchor="middle" font-size="20" fill="#000000">Test</text>
    </svg>
    """
  end

  @doc """
  Returns an SVG with colors that can be replaced in preprocessing.
  """
  def replaceable_svg do
    """
    <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" viewBox="0 0 100 100">
      <rect x="10" y="10" width="40" height="40" fill="#000000" />
      <rect x="50" y="50" width="40" height="40" fill="blue" />
    </svg>
    """
  end

  @doc """
  Returns an invalid SVG string for error testing.
  """
  def invalid_svg do
    "<svg>This is not valid SVG"
  end

  @doc """
  Returns an SVG with viewBox but no width/height attributes.
  """
  def viewbox_only_svg do
    """
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 150 150">
      <circle cx="75" cy="75" r="50" fill="#FF00FF" />
    </svg>
    """
  end

  @doc """
  Checks if binary data appears to be a valid PNG by checking magic bytes and structure.
  """
  def valid_png?(<<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, rest::binary>>) do
    # Check for IHDR chunk and IEND chunk
    with true <- has_png_chunk?(rest, "IHDR"),
         true <- has_png_chunk?(rest, "IEND"),
         true <- validate_png_chunks(rest) do
      true
    else
      _ -> false
    end
  end

  def valid_png?(_), do: false

  defp has_png_chunk?(data, chunk_type) when is_binary(data) do
    String.contains?(data, chunk_type)
  end

  defp validate_png_chunks(data) do
    # Validate first chunk (IHDR)
    case data do
      <<_length::32, "IHDR", _chunk_data::binary-size(13), crc::32, _rest::binary>> ->
        # Basic CRC validation for IHDR (just check it exists)
        crc != 0

      _ ->
        false
    end
  end

  @doc """
  Checks if binary data appears to be a valid JPEG by checking magic bytes and EOI marker.
  """
  def valid_jpeg?(<<0xFF, 0xD8, 0xFF, _rest::binary>> = data) do
    # Check for EOI (End of Image) marker at the end
    byte_size = byte_size(data)

    if byte_size >= 2 do
      <<_::binary-size(byte_size - 2), 0xFF, 0xD9>> = data
      true
    else
      false
    end
  rescue
    MatchError -> false
  end

  def valid_jpeg?(_), do: false

  @doc """
  Checks if binary data appears to be a valid GIF by checking magic bytes and trailer.
  """
  def valid_gif?(<<"GIF89a", _rest::binary>> = data) do
    # Check for GIF trailer (0x3B) at the end
    byte_size = byte_size(data)

    if byte_size >= 1 do
      <<_::binary-size(byte_size - 1), 0x3B>> = data
      true
    else
      false
    end
  rescue
    MatchError -> false
  end

  def valid_gif?(<<"GIF87a", _rest::binary>> = data) do
    byte_size = byte_size(data)

    if byte_size >= 1 do
      <<_::binary-size(byte_size - 1), 0x3B>> = data
      true
    else
      false
    end
  rescue
    MatchError -> false
  end

  def valid_gif?(_), do: false

  @doc """
  Checks if binary data appears to be a valid WebP by checking magic bytes and structure.
  """
  def valid_webp?(<<"RIFF", file_size::32-little, "WEBP", rest::binary>>) do
    # Verify RIFF size matches actual data size
    # RIFF size = file size - 8 (RIFF header)
    expected_data_size = file_size
    # +4 for "WEBP"
    actual_data_size = byte_size(rest) + 4

    # Allow some tolerance for padding
    # Check for valid chunk type (VP8, VP8L, or VP8X)
    abs(expected_data_size - actual_data_size) <= 1 and
      (String.starts_with?(rest, "VP8 ") or
         String.starts_with?(rest, "VP8L") or
         String.starts_with?(rest, "VP8X"))
  end

  def valid_webp?(_), do: false

  @doc """
  Validates that binary data matches the expected format.
  """
  def valid_format?(data, :png), do: valid_png?(data)
  def valid_format?(data, :jpg), do: valid_jpeg?(data)
  def valid_format?(data, :jpeg), do: valid_jpeg?(data)
  def valid_format?(data, :gif), do: valid_gif?(data)
  def valid_format?(data, :webp), do: valid_webp?(data)

  @doc """
  Extracts dimensions from PNG image data.
  Returns {width, height} or nil if parsing fails.
  """
  def get_png_dimensions(
        <<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, _::binary-size(8), width::32,
          height::32, _rest::binary>>
      ) do
    {width, height}
  end

  def get_png_dimensions(_), do: nil

  @doc """
  Extracts dimensions from JPEG image data.
  Returns {width, height} or nil if parsing fails.
  """
  def get_jpeg_dimensions(data) do
    case parse_jpeg_dimensions(data) do
      {width, height} when is_integer(width) and is_integer(height) -> {width, height}
      _ -> nil
    end
  end

  defp parse_jpeg_dimensions(<<0xFF, 0xD8, rest::binary>>), do: find_jpeg_sof(rest)
  defp parse_jpeg_dimensions(_), do: nil

  defp find_jpeg_sof(<<0xFF, marker, rest::binary>>) when marker in [0xC0, 0xC2] do
    # SOF0 or SOF2 marker
    <<_length::16, _precision::8, height::16, width::16, _rest::binary>> = rest
    {width, height}
  end

  defp find_jpeg_sof(<<0xFF, _marker, length::16, rest::binary>>) do
    # Skip this segment and continue
    segment_data_length = length - 2
    <<_::binary-size(segment_data_length), remaining::binary>> = rest
    find_jpeg_sof(remaining)
  end

  defp find_jpeg_sof(_), do: nil

  @doc """
  Extracts dimensions from GIF image data.
  Returns {width, height} or nil if parsing fails.
  """
  def get_gif_dimensions(<<"GIF89a", width::16-little, height::16-little, _rest::binary>>),
    do: {width, height}

  def get_gif_dimensions(<<"GIF87a", width::16-little, height::16-little, _rest::binary>>),
    do: {width, height}

  def get_gif_dimensions(_), do: nil

  @doc """
  Extracts dimensions from WebP image data.
  Returns {width, height} or nil if parsing fails.
  """
  def get_webp_dimensions(<<"RIFF", _size::32-little, "WEBP", rest::binary>>) do
    parse_webp_chunk(rest)
  end

  def get_webp_dimensions(_), do: nil

  defp parse_webp_chunk(<<"VP8 ", size::32-little, rest::binary>>) do
    # VP8 lossy format
    <<frame_data::binary-size(size), _::binary>> = rest
    # Skip 3 bytes (frame tag), then read width and height (2 bytes each, little-endian)
    <<_::24, width::16-little, height::16-little, _::binary>> = frame_data
    {width &&& 0x3FFF, height &&& 0x3FFF}
  end

  defp parse_webp_chunk(
         <<"VP8L", _size::32-little, 0x2F, byte1, byte2, byte3, byte4, _rest::binary>>
       ) do
    # VP8L lossless format
    # Width and height are 14-bit values packed LSB-first
    combined = byte1 + (byte2 <<< 8) + (byte3 <<< 16) + (byte4 <<< 24)
    width_minus_1 = combined &&& 0x3FFF
    height_minus_1 = combined >>> 14 &&& 0x3FFF
    {width_minus_1 + 1, height_minus_1 + 1}
  end

  defp parse_webp_chunk(
         <<"VP8X", _::binary-size(4), _flags::8, _reserved::24, width_minus_1::24-little,
           height_minus_1::24-little, _rest::binary>>
       ) do
    # VP8X extended format
    {width_minus_1 + 1, height_minus_1 + 1}
  end

  defp parse_webp_chunk(_), do: nil

  @doc """
  Gets dimensions for any supported format.
  Returns {width, height} or nil if parsing fails.
  """
  def get_dimensions(data, :png), do: get_png_dimensions(data)
  def get_dimensions(data, :jpg), do: get_jpeg_dimensions(data)
  def get_dimensions(data, :jpeg), do: get_jpeg_dimensions(data)
  def get_dimensions(data, :gif), do: get_gif_dimensions(data)
  def get_dimensions(data, :webp), do: get_webp_dimensions(data)

  @doc """
  Verifies that image dimensions match expected values.
  """
  def dimensions_match?(data, format, expected_width, expected_height) do
    case get_dimensions(data, format) do
      {^expected_width, ^expected_height} -> true
      _ -> false
    end
  end
end
