defmodule Svgager.ValidityTest do
  use ExUnit.Case, async: true
  alias Svgager.Converter
  alias Svgager.TestHelper

  describe "PNG structural validity" do
    test "PNG has valid magic bytes" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :png, width: 100)
      assert <<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, _::binary>> = data
    end

    test "PNG has required IHDR chunk" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :png, width: 100)
      assert data =~ "IHDR"
    end

    test "PNG has required IEND chunk" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :png, width: 100)
      assert data =~ "IEND"
    end

    test "PNG IEND is at the end" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :png, width: 100)
      # IEND should be near the end
      iend_position = :binary.match(data, "IEND") |> elem(0)
      file_size = byte_size(data)

      # IEND should be within last 20 bytes (12 bytes for IEND chunk + some padding)
      assert file_size - iend_position <= 20
    end

    test "PNG has IDAT chunk (image data)" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :png, width: 100)
      assert data =~ "IDAT"
    end
  end

  describe "JPEG structural validity" do
    test "JPEG has valid SOI marker" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :jpg, width: 100)
      assert <<0xFF, 0xD8, 0xFF, _::binary>> = data
    end

    test "JPEG has EOI marker" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :jpg, width: 100)
      byte_size = byte_size(data)
      assert <<_::binary-size(byte_size - 2), 0xFF, 0xD9>> = data
    end

    test "JPEG is not truncated" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :jpg, width: 100)
      assert TestHelper.valid_jpeg?(data)
    end

    test "JPEG has SOF marker" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :jpg, width: 100)
      # Should contain SOF0 (0xFFC0) or SOF2 (0xFFC2) marker
      assert data =~ <<0xFF, 0xC0>> or data =~ <<0xFF, 0xC2>>
    end
  end

  describe "GIF structural validity" do
    test "GIF has valid header" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :gif, width: 100)
      assert data =~ "GIF89a" or data =~ "GIF87a"
    end

    test "GIF has trailer" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :gif, width: 100)
      byte_size = byte_size(data)
      assert <<_::binary-size(byte_size - 1), 0x3B>> = data
    end

    test "GIF is complete" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :gif, width: 100)
      assert TestHelper.valid_gif?(data)
    end
  end

  describe "WebP structural validity" do
    test "WebP has valid RIFF header" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :webp, width: 100)
      assert <<"RIFF", _::32-little, "WEBP", _::binary>> = data
    end

    test "WebP has valid chunk type" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :webp, width: 100)
      <<"RIFF", _::32-little, "WEBP", chunk_type::binary-size(4), _::binary>> = data
      assert chunk_type in ["VP8 ", "VP8L", "VP8X"]
    end

    test "WebP RIFF size is correct" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :webp, width: 100)
      assert TestHelper.valid_webp?(data)
    end
  end

  describe "multi-format validity comparison" do
    test "all formats produce structurally valid images" do
      svg = TestHelper.simple_svg()

      formats = [:png, :jpg, :jpeg, :gif, :webp]

      for format <- formats do
        assert {:ok, data} = Converter.convert(svg, format: format, width: 200)

        assert TestHelper.valid_format?(data, format),
               "Format #{format} produced invalid image"
      end
    end

    test "images are valid at different sizes" do
      svg = TestHelper.simple_svg()

      sizes = [50, 100, 500, 1000]

      for size <- sizes do
        assert {:ok, data} = Converter.convert(svg, format: :png, width: size)
        assert TestHelper.valid_png?(data), "PNG invalid at size #{size}"
      end
    end

    test "complex SVG produces valid images in all formats" do
      svg = TestHelper.complex_svg()

      formats = [:png, :jpg, :gif, :webp]

      for format <- formats do
        assert {:ok, data} = Converter.convert(svg, format: format, width: 300)

        assert TestHelper.valid_format?(data, format),
               "Complex SVG produced invalid #{format}"
      end
    end
  end

  describe "image completeness" do
    test "PNG files are not truncated" do
      svg = TestHelper.complex_svg()

      assert {:ok, data} = Converter.convert(svg, format: :png, width: 500)

      # Check IEND is present and at the end
      assert data =~ "IEND"
      iend_position = :binary.match(data, "IEND") |> elem(0)
      file_size = byte_size(data)
      assert file_size - iend_position <= 20
    end

    test "JPEG files have proper termination" do
      svg = TestHelper.complex_svg()

      assert {:ok, data} = Converter.convert(svg, format: :jpg, width: 500)

      # Check EOI marker is at the end
      byte_size = byte_size(data)
      assert <<_::binary-size(byte_size - 2), 0xFF, 0xD9>> = data
    end

    test "images contain actual data, not just headers" do
      svg = TestHelper.simple_svg()

      # PNG should have IDAT (image data) chunk
      assert {:ok, png} = Converter.convert(svg, format: :png, width: 100)
      assert png =~ "IDAT"

      # File sizes should be reasonable (not just headers)
      assert byte_size(png) > 200
    end
  end

  describe "image data integrity" do
    test "same input produces same output" do
      svg = TestHelper.simple_svg()

      assert {:ok, data1} = Converter.convert(svg, format: :png, width: 200)
      assert {:ok, data2} = Converter.convert(svg, format: :png, width: 200)

      assert data1 == data2
    end

    test "different inputs produce different outputs" do
      svg1 = TestHelper.simple_svg()
      svg2 = TestHelper.complex_svg()

      assert {:ok, data1} = Converter.convert(svg1, format: :png, width: 200)
      assert {:ok, data2} = Converter.convert(svg2, format: :png, width: 200)

      assert data1 != data2
    end

    test "preprocessing changes output" do
      svg = TestHelper.replaceable_svg()

      assert {:ok, data1} = Converter.convert(svg, format: :png, width: 100)

      assert {:ok, data2} =
               Converter.convert(svg,
                 format: :png,
                 width: 100,
                 replacements: %{"#000000" => "#FF0000"}
               )

      assert data1 != data2
    end
  end
end
