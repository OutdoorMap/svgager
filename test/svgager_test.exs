defmodule SvgagerTest do
  use ExUnit.Case, async: true
  doctest Svgager

  alias Svgager.TestHelper

  describe "convert/2 - integration tests" do
    test "converts SVG to PNG through main API" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Svgager.convert(svg, format: :png, width: 100)
      assert is_binary(data)
      assert TestHelper.valid_format?(data, :png)
    end

    test "converts SVG to JPG through main API" do
      svg = TestHelper.complex_svg()

      assert {:ok, data} =
               Svgager.convert(svg,
                 format: :jpg,
                 width: 200,
                 height: 200,
                 background_color: "FFFFFF"
               )

      assert is_binary(data)
      assert TestHelper.valid_format?(data, :jpg)
    end

    test "converts SVG to WebP through main API" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Svgager.convert(svg, format: :webp, width: 150)
      assert is_binary(data)
      assert TestHelper.valid_format?(data, :webp)
    end

    test "handles preprocessing through main API" do
      svg = TestHelper.replaceable_svg()

      assert {:ok, data} =
               Svgager.convert(svg,
                 format: :png,
                 width: 100,
                 replacements: %{
                   "#000000" => "#FF5500",
                   "blue" => "green"
                 }
               )

      assert is_binary(data)
      assert TestHelper.valid_format?(data, :png)
    end

    test "handles errors through main API" do
      assert {:error, message} = Svgager.convert("invalid svg", format: :png, width: 100)
      assert is_binary(message)
      assert message =~ "Failed to parse SVG"
    end

    test "validates options through main API" do
      svg = TestHelper.simple_svg()

      assert {:error, message} = Svgager.convert(svg, width: 100)
      assert message == "format option is required"
    end
  end

  describe "end-to-end workflow" do
    test "complete workflow: read SVG, convert, write file" do
      svg = TestHelper.complex_svg()

      # Convert to PNG
      assert {:ok, png_data} = Svgager.convert(svg, format: :png, width: 300)
      assert byte_size(png_data) > 0

      # Verify it's a valid PNG
      assert TestHelper.valid_format?(png_data, :png)

      # Test with replacements
      assert {:ok, modified_data} =
               Svgager.convert(svg,
                 format: :png,
                 width: 300,
                 replacements: %{"#0000FF" => "#FF0000"}
               )

      assert byte_size(modified_data) > 0
      assert TestHelper.valid_format?(modified_data, :png)
    end

    test "converts same SVG to multiple formats" do
      svg = TestHelper.simple_svg()

      formats = [:png, :jpg, :jpeg, :gif, :webp]

      for format <- formats do
        assert {:ok, data} = Svgager.convert(svg, format: format, width: 100)
        assert is_binary(data)
        assert byte_size(data) > 0
        assert TestHelper.valid_format?(data, format), "Format #{format} validation failed"
      end
    end

    test "converts to different resolutions" do
      svg = TestHelper.simple_svg()

      sizes = [50, 100, 200, 500, 1000]

      for size <- sizes do
        assert {:ok, data} = Svgager.convert(svg, format: :png, width: size)
        assert is_binary(data)
        assert byte_size(data) > 0
      end
    end

    test "batch conversion with different options" do
      svg = TestHelper.simple_svg()

      conversions = [
        [format: :png, width: 100],
        [format: :jpg, width: 200, background_color: "FFFFFF"],
        [format: :webp, height: 150],
        [format: :gif, width: 100, height: 100, background_color: "000000"]
      ]

      for opts <- conversions do
        assert {:ok, data} = Svgager.convert(svg, opts)
        assert is_binary(data)
        assert byte_size(data) > 0
      end
    end
  end

  describe "real-world scenarios" do
    test "dynamic color theming with replacements" do
      svg = """
      <svg xmlns="http://www.w3.org/2000/svg" width="200" height="200">
        <rect width="200" height="200" fill="PRIMARY_COLOR"/>
        <circle cx="100" cy="100" r="50" fill="SECONDARY_COLOR"/>
      </svg>
      """

      # Theme 1: Blue and Green
      assert {:ok, _data} =
               Svgager.convert(svg,
                 format: :png,
                 width: 200,
                 replacements: %{
                   "PRIMARY_COLOR" => "#0000FF",
                   "SECONDARY_COLOR" => "#00FF00"
                 }
               )

      # Theme 2: Red and Yellow
      assert {:ok, _data} =
               Svgager.convert(svg,
                 format: :png,
                 width: 200,
                 replacements: %{
                   "PRIMARY_COLOR" => "#FF0000",
                   "SECONDARY_COLOR" => "#FFFF00"
                 }
               )
    end

    test "responsive image generation" do
      svg = TestHelper.complex_svg()

      # Generate multiple sizes for responsive design
      sizes = [
        {:thumbnail, 100},
        {:small, 300},
        {:medium, 600},
        {:large, 1200}
      ]

      for {_size_name, width} <- sizes do
        assert {:ok, data} = Svgager.convert(svg, format: :webp, width: width)
        assert is_binary(data)
        assert byte_size(data) > 0
      end
    end

    test "social media card generation" do
      svg = TestHelper.complex_svg()

      # Twitter card: 1200x628
      assert {:ok, twitter_data} =
               Svgager.convert(svg,
                 format: :jpg,
                 width: 1200,
                 height: 628,
                 background_color: "FFFFFF"
               )

      assert TestHelper.valid_format?(twitter_data, :jpg)

      # Facebook card: 1200x630
      assert {:ok, facebook_data} =
               Svgager.convert(svg,
                 format: :jpg,
                 width: 1200,
                 height: 630,
                 background_color: "FFFFFF"
               )

      assert TestHelper.valid_format?(facebook_data, :jpg)
    end

    test "icon generation in multiple sizes" do
      svg = """
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
        <path d="M12 2L2 7v10c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V7l-10-5z" fill="#4CAF50"/>
      </svg>
      """

      # Generate favicon sizes
      icon_sizes = [16, 32, 48, 64, 128, 256]

      for size <- icon_sizes do
        assert {:ok, data} = Svgager.convert(svg, format: :png, width: size, height: size)
        assert TestHelper.valid_format?(data, :png)
      end
    end
  end

  describe "performance and stress tests" do
    @tag :slow
    test "handles large SVG files" do
      # Create a complex SVG with many elements
      svg = """
      <svg xmlns="http://www.w3.org/2000/svg" width="1000" height="1000" viewBox="0 0 1000 1000">
        #{for i <- 1..100 do
        """
        <circle cx="#{rem(i * 47, 1000)}" cy="#{rem(i * 73, 1000)}" r="#{10 + rem(i, 20)}" fill="##{Integer.to_string(rem(i * 12345, 16_777_215), 16) |> String.pad_leading(6, "0")}"/>
        """
      end |> Enum.join("\n")}
      </svg>
      """

      assert {:ok, data} = Svgager.convert(svg, format: :png, width: 500)
      assert is_binary(data)
      assert byte_size(data) > 0
    end

    @tag :slow
    test "handles high resolution output" do
      svg = TestHelper.simple_svg()

      assert {:ok, data} = Svgager.convert(svg, format: :png, width: 4000, height: 4000)
      assert is_binary(data)
      assert byte_size(data) > 0
    end
  end
end
