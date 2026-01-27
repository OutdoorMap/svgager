defmodule Svgager.ConverterTest do
  use ExUnit.Case, async: true
  alias Svgager.Converter
  alias Svgager.TestHelper

  describe "convert/2 - format conversions" do
    test "converts SVG to PNG format" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :png, width: 100)
      assert is_binary(data)
      assert TestHelper.valid_format?(data, :png)
    end

    test "converts SVG to JPG format" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :jpg, width: 100)
      assert is_binary(data)
      assert TestHelper.valid_format?(data, :jpg)
    end

    test "converts SVG to JPEG format" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :jpeg, width: 100)
      assert is_binary(data)
      assert TestHelper.valid_format?(data, :jpeg)
    end

    test "converts SVG to GIF format" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :gif, width: 100)
      assert is_binary(data)
      assert TestHelper.valid_format?(data, :gif)
    end

    test "converts SVG to WebP format" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :webp, width: 100)
      assert is_binary(data)
      assert TestHelper.valid_format?(data, :webp)
    end

    test "converts complex SVG with multiple elements" do
      svg = TestHelper.complex_svg()

      assert {:ok, data} = Converter.convert(svg, format: :png, width: 200)
      assert is_binary(data)
      assert TestHelper.valid_format?(data, :png)
    end
  end

  describe "convert/2 - resolution handling" do
    test "converts with only width specified" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :png, width: 200)
      assert is_binary(data)
      assert TestHelper.valid_format?(data, :png)
    end

    test "converts with only height specified" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :png, height: 150)
      assert is_binary(data)
      assert TestHelper.valid_format?(data, :png)
    end

    test "converts with both width and height specified" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :png, width: 300, height: 200)
      assert is_binary(data)
      assert TestHelper.valid_format?(data, :png)
    end

    test "converts without width or height (uses SVG dimensions)" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :png)
      assert is_binary(data)
      assert TestHelper.valid_format?(data, :png)
    end

    test "converts SVG with viewBox only" do
      svg = TestHelper.viewbox_only_svg()

      assert {:ok, data} = Converter.convert(svg, format: :png, width: 150)
      assert is_binary(data)
      assert TestHelper.valid_format?(data, :png)
    end

    test "handles large dimensions" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :png, width: 2000)
      assert is_binary(data)
      assert TestHelper.valid_format?(data, :png)
    end

    test "handles small dimensions" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :png, width: 50)
      assert is_binary(data)
      assert TestHelper.valid_format?(data, :png)
    end
  end

  describe "convert/2 - background colors" do
    test "PNG ignores background color (uses transparency)" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} =
               Converter.convert(svg, format: :png, width: 100, background_color: "FF0000")

      assert is_binary(data)
      assert TestHelper.valid_format?(data, :png)
    end

    test "JPG uses background color" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} =
               Converter.convert(svg, format: :jpg, width: 100, background_color: "00FF00")

      assert is_binary(data)
      assert TestHelper.valid_format?(data, :jpg)
    end

    test "accepts background color with # prefix" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} =
               Converter.convert(svg, format: :jpg, width: 100, background_color: "#0000FF")

      assert is_binary(data)
      assert TestHelper.valid_format?(data, :jpg)
    end

    test "accepts background color without # prefix" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} =
               Converter.convert(svg, format: :jpg, width: 100, background_color: "FFFFFF")

      assert is_binary(data)
      assert TestHelper.valid_format?(data, :jpg)
    end

    test "WebP uses background color" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} =
               Converter.convert(svg, format: :webp, width: 100, background_color: "FF00FF")

      assert is_binary(data)
      assert TestHelper.valid_format?(data, :webp)
    end

    test "GIF uses background color" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} =
               Converter.convert(svg, format: :gif, width: 100, background_color: "FFFF00")

      assert is_binary(data)
      assert TestHelper.valid_format?(data, :gif)
    end

    test "uses default white background when not specified for JPG" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :jpg, width: 100)
      assert is_binary(data)
      assert TestHelper.valid_format?(data, :jpg)
    end
  end

  describe "convert/2 - SVG preprocessing with replacements" do
    test "replaces hex color codes in SVG" do
      svg = TestHelper.replaceable_svg()

      assert {:ok, data} =
               Converter.convert(svg,
                 format: :png,
                 width: 100,
                 replacements: %{"#000000" => "#FF0000"}
               )

      assert is_binary(data)
      assert TestHelper.valid_format?(data, :png)
    end

    test "replaces named colors in SVG" do
      svg = TestHelper.replaceable_svg()

      assert {:ok, data} =
               Converter.convert(svg,
                 format: :png,
                 width: 100,
                 replacements: %{"blue" => "red"}
               )

      assert is_binary(data)
      assert TestHelper.valid_format?(data, :png)
    end

    test "applies multiple replacements" do
      svg = TestHelper.replaceable_svg()

      assert {:ok, data} =
               Converter.convert(svg,
                 format: :png,
                 width: 100,
                 replacements: %{
                   "#000000" => "#FF0000",
                   "blue" => "green"
                 }
               )

      assert is_binary(data)
      assert TestHelper.valid_format?(data, :png)
    end

    test "handles empty replacements map" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Converter.convert(svg, format: :png, width: 100, replacements: %{})
      assert is_binary(data)
      assert TestHelper.valid_format?(data, :png)
    end

    test "handles replacements with no matches in SVG" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} =
               Converter.convert(svg,
                 format: :png,
                 width: 100,
                 replacements: %{"nonexistent" => "value"}
               )

      assert is_binary(data)
      assert TestHelper.valid_format?(data, :png)
    end
  end

  describe "convert/2 - error handling" do
    test "returns error when format is missing" do
      svg = TestHelper.simple_svg()

      assert {:error, message} = Converter.convert(svg, width: 100)
      assert message == "format option is required"
    end

    test "returns error for unsupported format" do
      svg = TestHelper.simple_svg()

      assert {:error, message} = Converter.convert(svg, format: :bmp, width: 100)
      assert message =~ "unsupported format"
      assert message =~ ":bmp"
    end

    test "returns error for invalid SVG" do
      svg = TestHelper.invalid_svg()

      assert {:error, message} = Converter.convert(svg, format: :png, width: 100)
      assert message =~ "Failed to parse SVG"
    end

    test "returns error for negative width" do
      svg = TestHelper.simple_svg()

      assert {:error, message} = Converter.convert(svg, format: :png, width: -100)
      assert message =~ "width must be a positive integer"
    end

    test "returns error for zero width" do
      svg = TestHelper.simple_svg()

      assert {:error, message} = Converter.convert(svg, format: :png, width: 0)
      assert message =~ "width must be a positive integer"
    end

    test "returns error for negative height" do
      svg = TestHelper.simple_svg()

      assert {:error, message} = Converter.convert(svg, format: :png, height: -100)
      assert message =~ "height must be a positive integer"
    end

    test "returns error for zero height" do
      svg = TestHelper.simple_svg()

      assert {:error, message} = Converter.convert(svg, format: :png, height: 0)
      assert message =~ "height must be a positive integer"
    end

    test "returns error for non-integer width" do
      svg = TestHelper.simple_svg()

      assert {:error, message} = Converter.convert(svg, format: :png, width: "100")
      assert message =~ "width must be a positive integer"
    end

    test "returns error for non-integer height" do
      svg = TestHelper.simple_svg()

      assert {:error, message} = Converter.convert(svg, format: :png, height: 99.5)
      assert message =~ "height must be a positive integer"
    end

    test "returns error for invalid replacements (not a map)" do
      svg = TestHelper.simple_svg()

      assert {:error, message} =
               Converter.convert(svg, format: :png, width: 100, replacements: "invalid")

      assert message =~ "replacements must be a map"
    end

    test "returns error for empty SVG string" do
      assert {:error, message} = Converter.convert("", format: :png, width: 100)
      assert message =~ "Failed to parse SVG"
    end

    test "returns error for non-string SVG input" do
      assert_raise FunctionClauseError, fn ->
        Converter.convert(123, format: :png, width: 100)
      end
    end
  end

  describe "convert/2 - edge cases" do
    test "handles SVG with special characters" do
      svg = """
      <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
        <text x="10" y="50">Special: &lt;&gt;&amp;</text>
      </svg>
      """

      assert {:ok, data} = Converter.convert(svg, format: :png, width: 100)
      assert is_binary(data)
      assert TestHelper.valid_format?(data, :png)
    end

    test "handles very small SVG" do
      svg = """
      <svg xmlns="http://www.w3.org/2000/svg" width="10" height="10">
        <rect width="10" height="10" fill="red"/>
      </svg>
      """

      assert {:ok, data} = Converter.convert(svg, format: :png, width: 10)
      assert is_binary(data)
      assert TestHelper.valid_format?(data, :png)
    end

    test "handles SVG with gradients" do
      svg = """
      <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
        <defs>
          <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:rgb(255,255,0);stop-opacity:1" />
            <stop offset="100%" style="stop-color:rgb(255,0,0);stop-opacity:1" />
          </linearGradient>
        </defs>
        <rect width="100" height="100" fill="url(#grad)" />
      </svg>
      """

      assert {:ok, data} = Converter.convert(svg, format: :png, width: 100)
      assert is_binary(data)
      assert TestHelper.valid_format?(data, :png)
    end

    test "handles SVG with transformations" do
      svg = """
      <svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
        <rect x="10" y="10" width="30" height="30" fill="blue" transform="rotate(45 25 25)"/>
      </svg>
      """

      assert {:ok, data} = Converter.convert(svg, format: :png, width: 100)
      assert is_binary(data)
      assert TestHelper.valid_format?(data, :png)
    end
  end
end
