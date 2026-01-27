import Config

# Development configuration
# In development, always build NIFs from source (requires Rust)
config :svgager,
  force_build_nif: true
