require "./src/unit"

# Test all Volume unit symbols work correctly
puts "Testing all Volume unit symbols:"

# Test all enum values as symbols
Unit::Volume::Unit.values.each do |unit|
  symbol_str = unit.to_s.downcase
  # Use Symbol.new to create symbol from string
  symbol = Symbol.new(symbol_str)
  begin
    volume = Unit::Volume.new(1, symbol)
    factor = Unit::Volume.conversion_factor(symbol)
    puts "✓ :#{symbol_str} -> #{volume.unit} (factor: #{factor})"
  rescue e
    puts "✗ :#{symbol_str} failed: #{e.message}"
  end
end

puts "\nTesting specific common symbols:"

# Test common cooking symbols
common_symbols = [:liter, :gallon, :cup, :milliliter, :quart, :pint, :fluidounce]
common_symbols.each do |symbol|
  begin
    volume = Unit::Volume.new(1, symbol)
    factor = Unit::Volume.conversion_factor(symbol)
    puts "✓ :#{symbol} -> #{volume.unit} (factor: #{factor})"
  rescue e
    puts "✗ :#{symbol} failed: #{e.message}"
  end
end

puts "\nAll symbol tests completed!"
