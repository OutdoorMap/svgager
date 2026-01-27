# Contributing to Svgager

Thank you for your interest in contributing to Svgager! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [How to Contribute](#how-to-contribute)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)
- [Reporting Issues](#reporting-issues)

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on what is best for the community
- Show empathy towards other community members
- Accept constructive criticism gracefully

### Unacceptable Behavior

- Harassment or discriminatory language
- Trolling or insulting comments
- Publishing others' private information
- Any conduct which could reasonably be considered inappropriate in a professional setting

## Getting Started

### Prerequisites

Before you begin, ensure you have:

- **Elixir** 1.19 or later
- **Rust** and **Cargo** (latest stable version)
- **Git** for version control

You can use [mise](https://mise.jdx.dev/) for managing Rust:

```bash
mise install rust@latest
mise use rust@latest
```

### Fork and Clone

1. Fork the repository on GitHub
2. Clone your fork locally:

```bash
git clone https://github.com/OutdoorMap/svgager.git
cd svgager
```

3. Add the upstream repository:

```bash
git remote add upstream https://github.com/OutdoorMap/svgager.git
```

## Development Setup

1. Install dependencies:

```bash
mix deps.get
```

2. Compile the project:

```bash
# Using mise (if installed)
mise exec -- mix compile

# Or if Rust is in your PATH
mix compile
```

3. Run tests to verify setup:

```bash
mise exec -- mix test
```

All 106 tests should pass.

## How to Contribute

### Types of Contributions

We welcome various types of contributions:

- **Bug Fixes**: Fix issues reported in the issue tracker
- **New Features**: Add support for new image formats, options, or capabilities
- **Performance Improvements**: Optimize existing code
- **Documentation**: Improve or add documentation
- **Tests**: Add or improve test coverage
- **Examples**: Create example code or use cases

### Finding Something to Work On

1. Check the [issue tracker](https://github.com/OutdoorMap/svgager/issues) for open issues
2. Look for issues labeled `good first issue` or `help wanted`
3. If you want to work on something new, open an issue first to discuss it

## Pull Request Process

### Before You Start

1. **Create an issue** (if one doesn't exist) to discuss the change
2. **Sync your fork** with the upstream repository:

```bash
git fetch upstream
git checkout main
git merge upstream/main
```

3. **Create a feature branch**:

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-number-description
```

### Making Changes

1. **Write your code**:
   - Follow the coding standards (see below)
   - Write tests for your changes
   - Update documentation as needed

2. **Test your changes**:

```bash
# Run all tests
mise exec -- mix test

# Run specific test file
mise exec -- mix test test/svgager/converter_test.exs

# Run with coverage
mise exec -- mix test --cover
```

3. **Format your code**:

```bash
# Format Elixir code
mix format

# Format Rust code
cd native/svgager_native
cargo fmt
```

4. **Check for warnings**:

```bash
# Elixir
mix compile --warnings-as-errors

# Rust
cd native/svgager_native
cargo clippy -- -D warnings
```

### Committing Changes

1. **Write clear commit messages**:

```
Add WebP animation support

- Implement frame extraction for animated WebP
- Add tests for multi-frame handling
- Update documentation with animation examples

Fixes #123
```

2. **Keep commits focused**: One logical change per commit

3. **Sign your commits** (optional but recommended):

```bash
git commit -s -m "Your commit message"
```

### Submitting a Pull Request

1. **Push your branch** to your fork:

```bash
git push origin feature/your-feature-name
```

2. **Open a Pull Request** on GitHub:
   - Use a clear, descriptive title
   - Reference any related issues
   - Describe what changed and why
   - Include screenshots for UI changes
   - List any breaking changes

3. **PR Template** (use this structure):

```markdown
## Description
Brief description of the changes

## Motivation
Why is this change needed?

## Changes Made
- List of changes
- Another change
- etc.

## Related Issues
Fixes #123
Relates to #456

## Testing
How did you test this?

## Checklist
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] Code formatted
- [ ] All tests pass
- [ ] No new warnings
```

### Code Review Process

1. Maintainers will review your PR
2. Address any feedback or requested changes
3. Once approved, a maintainer will merge your PR
4. Celebrate! 🎉

## Coding Standards

### Elixir Style

Follow the [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide):

- Use `mix format` for consistent formatting
- Use descriptive variable and function names
- Write clear documentation with `@doc` and `@moduledoc`
- Keep functions small and focused
- Use pattern matching effectively
- Prefer `with` for complex conditional logic

**Example:**

```elixir
@doc """
Converts SVG to image format.

## Examples

    iex> convert(svg, format: :png, width: 100)
    {:ok, <<...>>}
"""
@spec convert(String.t(), keyword()) :: {:ok, binary()} | {:error, String.t()}
def convert(svg_string, opts) when is_binary(svg_string) do
  # Implementation
end
```

### Rust Style

Follow the [Rust Style Guide](https://doc.rust-lang.org/nightly/style-guide/):

- Use `cargo fmt` for formatting
- Use `cargo clippy` for linting
- Write documentation comments with `///`
- Use descriptive error messages
- Prefer `Result` for error handling
- Keep functions focused and testable

**Example:**

```rust
/// Converts SVG data to image format.
///
/// # Arguments
///
/// * `svg_data` - SVG content as string
/// * `format` - Output format ("png", "jpg", etc.)
///
/// # Returns
///
/// * `Ok(Vec<u8>)` - Encoded image data
/// * `Err(String)` - Error message
pub fn convert_svg_to_image(
    svg_data: String,
    format: String,
) -> Result<Vec<u8>, String> {
    // Implementation
}
```

## Testing Guidelines

### Writing Tests

1. **Every feature needs tests**:
   - Unit tests for individual functions
   - Integration tests for workflows
   - Validity tests for output

2. **Test organization**:
   - `test/svgager/converter_test.exs` - Unit tests
   - `test/svgager/dimension_test.exs`
    - Dimension tests
   - `test/svgager/validity_test.exs` - Validity tests
   - `test/svgager_test.exs` - Integration tests

3. **Test naming**:

```elixir
test "descriptive name of what is being tested" do
  # Arrange
  svg = TestHelper.simple_svg()

  # Act
  {:ok, data} = Converter.convert(svg, format: :png, width: 100)

  # Assert
  assert is_binary(data)
  assert TestHelper.valid_png?(data)
end
```

4. **Use test helpers**:

```elixir
# Available helpers in TestHelper module
TestHelper.simple_svg()          # Basic test SVG
TestHelper.complex_svg()         # Multi-element SVG
TestHelper.valid_format?(data, :png)  # Validate format
TestHelper.get_dimensions(data, :png) # Extract dimensions
```

### Running Tests

```bash
# All tests
mise exec -- mix test

# Specific file
mise exec -- mix test test/svgager/converter_test.exs

# Specific test
mise exec -- mix test test/svgager/converter_test.exs:42

# With coverage
mise exec -- mix test --cover

# Exclude slow tests
mise exec -- mix test --exclude slow
```

### Test Coverage

- Aim for 100% coverage of new code
- Don't skip tests or mark them as pending without reason
- Test both success and error cases
- Test edge cases (empty input, very large input, etc.)

## Documentation

### Code Documentation

1. **Module documentation** (`@moduledoc`):
   - Purpose of the module
   - Usage examples
   - Important notes

2. **Function documentation** (`@doc`):
   - What the function does
   - Parameters and their types
   - Return values
   - Examples
   - Raised exceptions or errors

3. **Type specifications** (`@spec`):
   - Always include for public functions
   - Use proper Elixir types

### User Documentation

When adding features:

1. Update **README.md** with examples
2. Update **DEVELOPMENT.md** if changing dev workflow
3. Add entries to **TEST_DOCUMENTATION.md** for new tests
4. Create specific docs for major features

### Documentation Style

- Use clear, simple language
- Include code examples
- Explain the "why", not just the "what"
- Keep examples up-to-date with code changes

## Reporting Issues

### Before Opening an Issue

1. **Search existing issues** to avoid duplicates
2. **Check documentation** - your question might be answered
3. **Try the latest version** - the issue might be fixed

### Bug Reports

Include:

- **Svgager version**
- **Elixir version** (`elixir --version`)
- **Rust version** (`rustc --version`)
- **Operating system**
- **Minimal reproduction code**
- **Expected behavior**
- **Actual behavior**
- **Error messages** (full stack trace)

**Template:**

```markdown
## Description
Brief description of the bug

## Environment
- Svgager version: 0.1.0
- Elixir version: 1.19.4
- Rust version: 1.92.0
- OS: macOS 14.2

## Reproduction
```elixir
svg = "..."
{:ok, data} = Svgager.convert(svg, format: :png, width: 100)
# Error occurs here
```

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Error Message
```
** (RuntimeError) Error message here
```
```

### Feature Requests

Include:

- **Use case**: Why do you need this feature?
- **Proposed API**: How should it work?
- **Alternatives**: What alternatives have you considered?
- **Examples**: Show example usage

## Development Tips

### Debugging

1. **Use IEx**:

```elixir
# In your code
require IEx
IEx.pry()
```

2. **Rust debugging**:

```rust
eprintln!("Debug: {:?}", variable);
```

3. **Run specific test**:

```bash
mise exec -- mix test test/svgager/converter_test.exs:42 --trace
```

### Performance

- Use `:timer.tc/1` to measure Elixir code
- Use `criterion` for Rust benchmarks
- Profile before optimizing

### Common Pitfalls

1. **Forgot to format**: Run `mix format` and `cargo fmt`
2. **Tests fail on CI**: Ensure Rust is available
3. **Import errors**: Check `import Bitwise` for bitwise operations
4. **Binary handling**: Use `rustler::Binary` for returning binary data

## Release Process (Maintainers Only)

1. Update version in `mix.exs`
2. Update `CHANGELOG.md`
3. Build precompiled binaries for all platforms
4. Generate checksums
5. Create GitHub release with binaries
6. Publish to Hex.pm: `mix hex.publish`

## Questions?

- **Documentation**: Check README.md and DEVELOPMENT.md
- **Issues**: Open an issue on GitHub
- **Discussions**: Use GitHub Discussions for questions

## License

By contributing to Svgager, you agree that your contributions will be licensed under the MIT License.

Thank you for contributing! 🎉
