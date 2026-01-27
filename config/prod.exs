import Config

# Production configuration
# In production, use precompiled binaries (no Rust required)
# Set SVGAGER_BUILD=true to override and force building from source
config :svgager,
  force_build_nif: false
