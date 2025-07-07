# Rust Backend

Net-hippie now supports an optional high-performance Rust backend powered by [reqwest](https://github.com/seanmonstar/reqwest) and [Magnus](https://github.com/matsadler/magnus).

## Features

- **Zero Breaking Changes**: Existing code works unchanged
- **Environment Variable Control**: Toggle with `NET_HIPPIE_RUST=true`
- **Automatic Fallback**: Falls back to Ruby implementation if Rust extension unavailable
- **High Performance**: Significantly faster HTTP requests using Rust's reqwest
- **Async Support**: Built on Tokio for efficient I/O operations
- **Future Streaming**: Architecture ready for streaming response support

## Installation

### Option 1: Install from Source (Recommended for Rust Backend)

```bash
# Clone and build with Rust extension
git clone https://github.com/xlgmokha/net-hippie.git
cd net-hippie
cargo build --release  # Optional: pre-build Rust extension
bundle install
```

### Option 2: Install from RubyGems

```bash
gem install net-hippie
```

> **Note**: When installing from RubyGems, the Rust extension will be built automatically if Rust is available. If Rust is not installed, it will fall back to the Ruby implementation.

## Requirements

- **Ruby**: >= 2.5.0 (same as before)
- **Rust**: >= 1.70.0 (optional, for Rust backend)
- **Cargo**: Latest stable (comes with Rust)

### Installing Rust

```bash
# Install Rust via rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Or via package managers
brew install rust        # macOS
apt install rustc cargo  # Ubuntu/Debian
```

## Usage

### Basic Usage (No Changes Required)

```ruby
# Your existing code works unchanged
require 'net/hippie'

# All these work exactly as before
response = Net::Hippie.get('https://api.github.com/users/octocat')
client = Net::Hippie::Client.new
response = client.post('https://httpbin.org/post', body: { foo: 'bar' })
```

### Enable Rust Backend

```bash
# Set environment variable to enable Rust backend
export NET_HIPPIE_RUST=true

# Now run your Ruby application
ruby your_app.rb
```

Or programmatically:

```ruby
# Enable Rust backend in your application
ENV['NET_HIPPIE_RUST'] = 'true'
require 'net/hippie'

# All subsequent requests will use the Rust backend
response = Net::Hippie.get('https://api.github.com/users/octocat')
```

### Check Backend Status

```ruby
require 'net/hippie'

# Check if Rust backend is available
puts "Rust available: #{Net::Hippie::RustBackend.available?}"

# Check if Rust backend is enabled
puts "Rust enabled: #{Net::Hippie::RustBackend.enabled?}"
```

## Performance Benefits

The Rust backend provides significant performance improvements:

- **Faster HTTP requests**: Rust's reqwest is highly optimized
- **Better concurrency**: Built on Tokio for efficient async I/O
- **Lower memory usage**: Rust's zero-cost abstractions
- **Type safety**: Compile-time guarantees prevent runtime errors

## Compatibility

- **100% API Compatibility**: All existing methods work identically
- **Error Handling**: Same exceptions are raised in both backends
- **Response Objects**: Identical behavior for response handling
- **Headers**: Full header support in both backends
- **Authentication**: Basic and Bearer auth work in both backends
- **Redirects**: Redirect handling works identically
- **Retries**: Retry logic with exponential backoff in both backends

## Troubleshooting

### Rust Extension Won't Build

If you see Rust compilation errors:

1. **Update Rust**: `rustup update`
2. **Install build tools**:
   ```bash
   # macOS
   xcode-select --install
   
   # Ubuntu/Debian
   sudo apt install build-essential
   ```
3. **Check Ruby headers**: Make sure Ruby development headers are installed

### Falling Back to Ruby

The gem automatically falls back to Ruby if:
- Rust is not installed
- Rust extension compilation fails
- `NET_HIPPIE_RUST` is not set to `'true'`

This ensures your application continues working regardless of Rust availability.

### Debug Information

```ruby
require 'net/hippie'

# Check which backend is being used
if Net::Hippie::RustBackend.enabled?
  puts "Using Rust backend (fast!)"
else
  puts "Using Ruby backend (compatible)"
end
```

## Development

### Building the Extension

```bash
# Build Rust extension
cargo build --release

# Or through Ruby's extension system
ruby extconf.rb
make
```

### Running Tests

```bash
# Test Ruby backend (default)
bin/test

# Test with Rust backend enabled
NET_HIPPIE_RUST=true bin/test
```

### Contributing

When contributing to the Rust backend:

1. Ensure both Ruby and Rust tests pass
2. Maintain API compatibility
3. Update this documentation for any changes
4. Add appropriate test coverage

## Future Features

- **Streaming Responses**: Support for streaming large responses
- **HTTP/2**: Take advantage of HTTP/2 multiplexing
- **WebSocket Support**: Potential WebSocket client support
- **Custom TLS**: Advanced TLS configuration options

## License

Same as net-hippie: MIT License