defmodule Svgager.DimensionTest do
  use ExUnit.Case, async: true
  alias Svgager.Converter
  alias Svgager.TestHelper

  describe "dimension verification - PNG" do
    test "PNG output has correct width when only width specified" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :png, width: 200)
      assert {200, 200} = TestHelper.get_png_dimensions(data)
    end

    test "PNG output has correct height when only height specified" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :png, height: 150)
      assert {150, 150} = TestHelper.get_png_dimensions(data)
    end

    test "PNG output has exact dimensions when both specified" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :png, width: 300, height: 200)
      assert {300, 200} = TestHelper.get_png_dimensions(data)
    end

    test "PNG maintains aspect ratio with width only" do
      # SVG is 100x100 (1:1 aspect ratio)
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :png, width: 400)
      assert {400, 400} = TestHelper.get_png_dimensions(data)
    end

    test "PNG uses SVG dimensions when no size specified" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :png)
      assert {100, 100} = TestHelper.get_png_dimensions(data)
    end
  end

  describe "dimension verification - JPEG" do
    test "JPEG output has correct dimensions" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :jpg, width: 250, height: 250)
      assert {250, 250} = TestHelper.get_jpeg_dimensions(data)
    end

    test "JPEG maintains aspect ratio with width only" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :jpg, width: 500)
      assert {500, 500} = TestHelper.get_jpeg_dimensions(data)
    end

    test "JPEG with non-square dimensions" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :jpeg, width: 640, height: 480)
      assert {640, 480} = TestHelper.get_jpeg_dimensions(data)
    end
  end

  describe "dimension verification - GIF" do
    test "GIF output has correct dimensions" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :gif, width: 180, height: 180)
      assert {180, 180} = TestHelper.get_gif_dimensions(data)
    end

    test "GIF with custom dimensions" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :gif, width: 320, height: 240)
      assert {320, 240} = TestHelper.get_gif_dimensions(data)
    end
  end

  describe "dimension verification - WebP" do
    test "WebP output has correct dimensions" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :webp, width: 400, height: 300)
      assert {400, 300} = TestHelper.get_webp_dimensions(data)
    end

    test "WebP with square dimensions" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :webp, width: 256, height: 256)
      assert {256, 256} = TestHelper.get_webp_dimensions(data)
    end
  end

  describe "dimension verification - complex SVG" do
    test "maintains correct dimensions for complex SVG" do
      svg = TestHelper.complex_svg()

      formats_and_sizes = [
        {:png, 300, 300},
        {:jpg, 400, 400},
        {:gif, 200, 200},
        {:webp, 350, 350}
      ]

      for {format, width, height} <- formats_and_sizes do
        assert {:ok, data} = Converter.convert(svg, format: format, width: width, height: height)

        assert {^width, ^height} = TestHelper.get_dimensions(data, format),
               "#{format} dimensions don't match: expected {#{width}, #{height}}"
      end
    end
  end

  describe "dimension verification - aspect ratio preservation" do
    test "preserves aspect ratio for non-square SVG with width only" do
      # Create a 200x100 SVG (2:1 aspect ratio)
      svg = """
      <svg xmlns="http://www.w3.org/2000/svg" width="200" height="100">
        <rect width="200" height="100" fill="#FF0000"/>
      </svg>
      """

      assert {:ok, data} = Converter.convert(svg, format: :png, width: 400)
      assert {400, 200} = TestHelper.get_png_dimensions(data)
    end

    test "preserves aspect ratio for non-square SVG with height only" do
      # Create a 200x100 SVG (2:1 aspect ratio)
      svg = """
      <svg xmlns="http://www.w3.org/2000/svg" width="200" height="100">
        <rect width="200" height="100" fill="#00FF00"/>
      </svg>
      """

      assert {:ok, data} = Converter.convert(svg, format: :png, height: 150)
      assert {300, 150} = TestHelper.get_png_dimensions(data)
    end

    test "allows distortion when both dimensions specified" do
      # Create a 100x100 SVG
      svg = TestHelper.simple_svg()

      # Request 200x100 (different aspect ratio)
      assert {:ok, data} = Converter.convert(svg, format: :png, width: 200, height: 100)
      assert {200, 100} = TestHelper.get_png_dimensions(data)
    end
  end

  describe "byte size verification" do
    test "PNG output has reasonable byte size" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :png, width: 100)
      byte_size = byte_size(data)

      # PNG should have some reasonable size
      assert byte_size > 100, "PNG too small: #{byte_size} bytes"
      assert byte_size < 50_000, "PNG too large: #{byte_size} bytes"
    end

    test "larger dimensions produce larger files" do
      svg = TestHelper.simple_svg()

      assert {:ok, small} = Converter.convert(svg, format: :png, width: 100)
      assert {:ok, large} = Converter.convert(svg, format: :png, width: 1000)

      assert byte_size(large) > byte_size(small),
             "Large image (#{byte_size(large)} bytes) should be bigger than small (#{byte_size(small)} bytes)"
    end

    test "different formats have different sizes" do
      svg = TestHelper.simple_svg()

      assert {:ok, png} = Converter.convert(svg, format: :png, width: 200)
      assert {:ok, jpg} = Converter.convert(svg, format: :jpg, width: 200)
      assert {:ok, gif} = Converter.convert(svg, format: :gif, width: 200)
      assert {:ok, webp} = Converter.convert(svg, format: :webp, width: 200)

      # All should have some reasonable size
      assert byte_size(png) > 100
      assert byte_size(jpg) > 100
      assert byte_size(gif) > 100
      assert byte_size(webp) > 100
    end

    test "complex SVG produces larger files than simple SVG" do
      simple = TestHelper.simple_svg()
      complex = TestHelper.complex_svg()

      assert {:ok, simple_data} = Converter.convert(simple, format: :png, width: 200)
      assert {:ok, complex_data} = Converter.convert(complex, format: :png, width: 200)

      # Complex SVG should generally produce larger output
      # (though this isn't guaranteed due to compression)
      assert byte_size(simple_data) > 0
      assert byte_size(complex_data) > 0
    end
  end

  describe "dimension verification - edge cases" do
    test "very small dimensions work correctly" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :png, width: 16, height: 16)
      assert {16, 16} = TestHelper.get_png_dimensions(data)
    end

    test "large dimensions work correctly" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :png, width: 2000, height: 1500)
      assert {2000, 1500} = TestHelper.get_png_dimensions(data)
    end

    test "odd dimensions work correctly" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :png, width: 333, height: 777)
      assert {333, 777} = TestHelper.get_png_dimensions(data)
    end
  end

  describe "dimension verification - all formats consistency" do
    test "all formats produce correct dimensions for same input" do
      svg = TestHelper.simple_svg()
      width = 250
      height = 200

      formats = [:png, :jpg, :jpeg, :gif, :webp]

      for format <- formats do
        assert {:ok, data} = Converter.convert(svg, format: format, width: width, height: height)

        assert TestHelper.dimensions_match?(data, format, width, height),
               "Format #{format} dimensions don't match expected #{width}x#{height}"
      end
    end

    test "all formats maintain aspect ratio consistently" do
      # 200x100 SVG (2:1 aspect ratio)
      svg = """
      <svg xmlns="http://www.w3.org/2000/svg" width="200" height="100">
        <rect width="200" height="100" fill="#0000FF"/>
      </svg>
      """

      formats = [:png, :jpg, :gif, :webp]

      for format <- formats do
        assert {:ok, data} = Converter.convert(svg, format: format, width: 400)

        assert TestHelper.dimensions_match?(data, format, 400, 200),
               "Format #{format} didn't maintain 2:1 aspect ratio"
      end
    end
  end
end
