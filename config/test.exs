import Config

# Test configuration
# In test environment, always build NIFs from source (requires Rust)
config :svgager,
  force_build_nif: true
