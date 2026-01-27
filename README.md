# Svgager

High-performance SVG to image conversion library for Elixir, powered by Rust via Rustler.

## Features

- **Multiple Output Formats**: Convert SVG to PNG, JPG, JPEG, GIF, or WebP
- **Resolution Control**: Set output width, height, or both dimensions
- **Aspect Ratio Preservation**: Automatically maintains aspect ratio when only one dimension is specified
- **Transparent Backgrounds**: PNG format supports transparency by default
- **Configurable Backgrounds**: Other formats support custom background colors (hex format)
- **SVG Preprocessing**: Replace strings in SVG content before conversion (useful for dynamic color changes)
- **High Performance**: Built with Rust for maximum speed and efficiency

## Prerequisites

### For End Users (Installing as Dependency)

**Elixir** 1.19 or later

**Note**: Rust is **NOT required** for end users! Svgager uses precompiled NIFs that work out of the box on supported platforms (Linux, macOS, Windows).

### For Developers (Contributing/Testing)

**Elixir** 1.19 or later
**Rust** and **Cargo** - **REQUIRED** for running tests and development

> **Quick Summary**:
> - **End users** (adding to your app): No Rust needed
> - **Contributors** (running `mix test`): Rust required

### Supported Platforms (Precompiled Binaries)

Precompiled binaries are provided for:
- Linux (x86_64, aarch64)
- macOS (x86_64, aarch64/Apple Silicon)
- Windows (x86_64)

### Building from Source (Optional)

If you need to compile from source, you'll need Rust and Cargo:

```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Restart terminal or run:
source $HOME/.cargo/env

# Verify installation
cargo --version
rustc --version

# Force compilation from source
export SVGAGER_BUILD=true
mix deps.compile svgager
```

Or visit [https://rustup.rs/](https://rustup.rs/) for other installation methods.

## Installation

Add `svgager` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:svgager, "~> 0.1.0"}
  ]
end
```

Then run:

```bash
mix deps.get
mix compile
```

### Precompiled Binaries

Svgager uses `rustler_precompiled` to provide precompiled NIFs for common platforms. When you run `mix deps.get`, it will automatically download the appropriate precompiled binary for your platform from GitHub releases.

**Environment Variables:**

- `SVGAGER_BUILD=true` - Force compilation from source instead of using precompiled binaries
- `RUSTLER_PRECOMPILED_FORCE_BUILD=true` - Alternative way to force building from source

**For Package Maintainers:**

To release precompiled binaries:

```bash
# 1. Update version in mix.exs
# 2. Update the base_url in lib/svgager/native.ex with your GitHub repository
# 3. Run the release helper
mix rustler_precompiled.download Svgager.Native --all --print

# 4. Upload the generated .tar.gz files to GitHub releases
# 5. Generate checksums
mix rustler_precompiled.download Svgager.Native --all --print-checksum > checksum-Elixir.Svgager.Native.exs

# 6. Commit the checksum file
```

## Usage

### Basic Conversion

```elixir
# Read an SVG file
svg_content = File.read!("input.svg")

# Convert to PNG with transparency (800px width, height auto-calculated)
{:ok, png_data} = Svgager.convert(svg_content, format: :png, width: 800)
File.write!("output.png", png_data)
```

### JPG with Background Color

```elixir
# Convert to JPG with red background
{:ok, jpg_data} = Svgager.convert(svg_content,
  format: :jpg,
  width: 1200,
  height: 800,
  background_color: "FF0000"
)
File.write!("output.jpg", jpg_data)
```

### WebP with Custom Resolution

```elixir
# Convert to WebP maintaining aspect ratio
{:ok, webp_data} = Svgager.convert(svg_content,
  format: :webp,
  width: 1024,
  background_color: "FFFFFF"
)
File.write!("output.webp", webp_data)
```

### SVG Preprocessing

You can replace strings in the SVG before conversion, useful for changing colors dynamically:

```elixir
# Change colors before conversion
{:ok, png_data} = Svgager.convert(svg_content,
  format: :png,
  width: 800,
  replacements: %{
    "#000000" => "#FF5500",
    "#FFFFFF" => "#00AAFF",
    "blue" => "red"
  }
)
```

### GIF Format

```elixir
# Convert to GIF with white background
{:ok, gif_data} = Svgager.convert(svg_content,
  format: :gif,
  width: 600,
  height: 400,
  background_color: "FFFFFF"
)
File.write!("output.gif", gif_data)
```

## API Reference

### `Svgager.convert/2`

Converts SVG to the specified image format and returns binary data.

#### Parameters

- `svg_string` (String.t) - The SVG content as a string
- `opts` (Keyword.t) - Conversion options

#### Options

- `:format` (required) - Output format. One of `:png`, `:jpg`, `:jpeg`, `:gif`, or `:webp`
- `:width` (optional) - Output width in pixels (integer). If only width is provided, height is calculated to maintain aspect ratio
- `:height` (optional) - Output height in pixels (integer). If only height is provided, width is calculated to maintain aspect ratio
- `:background_color` (optional) - Background color as hex string (e.g., "FFFFFF" or "#FF0000"). Ignored for PNG format which uses transparency. Defaults to "FFFFFF" (white) for other formats
- `:replacements` (optional) - Map of string replacements to apply to SVG before conversion (e.g., `%{"#000000" => "#FF0000"}`)

When both `:width` and `:height` are provided, the output uses exact dimensions (may distort if aspect ratio doesn't match original SVG).

#### Returns

- `{:ok, binary_data}` - Binary image data on success
- `{:error, reason}` - Error string on failure

## Error Handling

```elixir
case Svgager.convert(svg_content, format: :png, width: 800) do
  {:ok, image_data} ->
    File.write!("output.png", image_data)
    IO.puts("Conversion successful!")

  {:error, reason} ->
    IO.puts("Conversion failed: #{reason}")
end
```

## Development

### Prerequisites for Development

**Important**: Rust and Cargo are **REQUIRED** for development and testing!

While end users don't need Rust (they use precompiled binaries), developers need Rust to:
- Run tests locally
- Make changes to the Rust code
- Build the library from source

**Install Rust:**

```bash
# Option 1: Using rustup (recommended)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# Option 2: Using mise (if you use mise for version management)
mise install rust@latest
mise use rust@latest

# Verify installation
cargo --version
rustc --version
```

### Setting Up Development Environment

The library **automatically builds from source** in dev/test mode (configured via `config/dev.exs` and `config/test.exs`):

```bash
# Clone the repository
git clone <repository-url>
cd svgager

# Install dependencies
mix deps.get

# Compile (automatically builds Rust NIF from source in dev mode)
mix compile

# Run tests
mix test
```

**Build Configuration:**

The build behavior is controlled by Mix configs:

- **`config/dev.exs`**: Sets `force_build_nif: true` (builds from source)
- **`config/test.exs`**: Sets `force_build_nif: true` (builds from source)
- **`config/prod.exs`**: Sets `force_build_nif: false` (uses precompiled binaries)

You can override this with the `SVGAGER_BUILD` environment variable:

```bash
# Force building from source in any environment
SVGAGER_BUILD=true mix compile

# Or export it for your session
export SVGAGER_BUILD=true
mix compile
```

**Development Tips:**

- The Rust NIF compiles in debug mode by default (faster compilation)
- Use `MIX_ENV=prod mix compile` to compile in release mode (optimized, slower compilation)
- The first compilation will take a few minutes (Rust dependencies are cached after that)
- Subsequent recompiles are much faster

### Project Structure

```
svgager/
├── lib/
│   ├── svgager.ex              # Main public API
│   └── svgager/
│       ├── converter.ex         # High-level conversion logic
│       └── native.ex            # NIF module definition
├── native/
│   └── svgager_native/
│       ├── Cargo.toml           # Rust dependencies
│       └── src/
│           ├── lib.rs           # Rust NIF entry point
│           └── converter.rs     # Rust conversion implementation
├── test/
│   └── svgager_test.exs
└── mix.exs
```

## Technical Details

### Rust Dependencies

- **rustler** - Elixir NIF bindings
- **resvg** - High-quality SVG rendering
- **usvg** - SVG parsing and tree representation
- **tiny-skia** - 2D rendering backend
- **image** - Multi-format image encoding

## Performance

Svgager leverages Rust's performance for fast SVG rendering and image encoding. The library uses resvg, which is widely regarded as one of the highest-quality SVG renderers available.

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines on:

- Setting up your development environment
- Coding standards and style guides
- Testing requirements
- Pull request process
- Reporting issues

### Quick Start for Contributors

```bash
# Fork and clone the repository
git clone https://github.com/OutdoorMap/svgager.git
cd svgager

# Install dependencies
mix deps.get

# Compile (requires Rust)
mise exec -- mix compile

# Run tests
mise exec -- mix test

# Format code before committing
mix format
cd native/svgager_native && cargo fmt
```

### Ways to Contribute

- Report bugs and issues
- Suggest new features or improvements
- Improve documentation
- Submit pull requests
- Star the project on GitHub

## License

Copyright (c) 2026 OutdoorMap AB

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### What This Means

**You can:**
- Use this library in commercial projects
- Modify and distribute the code
- Use it privately
- Sublicense it

**You must:**
- Include the license and copyright notice
- Acknowledge the original authors

**You cannot:**
- Hold the authors liable for damages
- Claim warranty coverage

## Acknowledgments

- Built with [Rustler](https://github.com/rusterlium/rustler) for Elixir/Rust integration
- Uses [resvg](https://github.com/RazrFalcon/resvg) for high-quality SVG rendering
- Powered by [tiny-skia](https://github.com/RazrFalcon/tiny-skia) for 2D graphics
- Image encoding via [image-rs](https://github.com/image-rs/image)

## Support

- **Documentation**: See [README.md](README.md) and [CONTRIBUTING.md](CONTRIBUTING.md)
- **Issues**: [GitHub Issues](https://github.com/OutdoorMap/svgager/issues)
- **Discussions**: [GitHub Discussions](https://github.com/OutdoorMap/svgager/discussions)

## Project Status

- **Production Ready**: All core features implemented and tested
- **Well Tested**: 106 tests covering all functionality
- **Documented**: Comprehensive documentation and examples
- **Precompiled Binaries**: Coming soon (requires GitHub releases setup)

## Roadmap

Potential future enhancements:

- [ ] Additional image formats (AVIF, TIFF, BMP)
- [ ] SVG animation support
- [ ] Image optimization options
- [ ] Batch conversion utilities
- [ ] CLI tool for command-line usage
- [ ] More preprocessing options (filters, effects)

Suggestions welcome! Open an issue to discuss new features.
