require 'mkmf'

# Check if Rust is available
def rust_available?
  system('cargo --version > /dev/null 2>&1')
end

if rust_available?
  # Use cargo to build the Rust extension
  system('cargo build --release') or abort 'Cargo build failed'
  
  # Copy the built library to the expected location
  ext_name = 'net_hippie_ext'
  lib_path = case RUBY_PLATFORM
             when /darwin/
               "target/release/lib#{ext_name}.dylib"
             when /linux/
               "target/release/lib#{ext_name}.so"
             when /mingw/
               "target/release/#{ext_name}.dll"
             else
               abort "Unsupported platform: #{RUBY_PLATFORM}"
             end
  
  target_path = "#{ext_name}.#{RbConfig::CONFIG['DLEXT']}"
  
  if File.exist?(lib_path)
    FileUtils.cp(lib_path, target_path)
    puts "Successfully built Rust extension: #{target_path}"
  else
    abort "Rust library not found at: #{lib_path}"
  end
  
  # Create a dummy Makefile since mkmf expects one
  create_makefile(ext_name)
else
  puts "Warning: Rust not available, skipping native extension build"
  puts "The gem will fall back to pure Ruby implementation"
  
  # Create a dummy Makefile that does nothing
  File.open('Makefile', 'w') do |f|
    f.puts "all:\n\t@echo 'Skipping Rust extension build'"
    f.puts "install:\n\t@echo 'Skipping Rust extension install'"
    f.puts "clean:\n\t@echo 'Skipping Rust extension clean'"
  end
end