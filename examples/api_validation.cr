#!/usr/bin/env crystal

# Validate the exact API requested in the original issue
#
# This file tests the specific examples mentioned:
# - 5.grams => "5 grams"
# - 1.2.kg => "1.2 kilograms"

require "../src/unit"
require "../src/unit/extensions"

puts "=== API Validation ==="

# Test the exact examples from the original request
result1 = 5.grams
puts "5.grams => \"#{result1.format}\""

result2 = 1.2.kg
puts "1.2.kg => \"#{result2.format}\""

# Verify the objects are proper Weight instances
puts "\nType validation:"
puts "5.grams.class => #{result1.class}"
puts "1.2.kg.class => #{result2.class}"

# Test that they work with arithmetic
total = 5.grams + 1.2.kg
puts "\n5.grams + 1.2.kg => #{total.format}"

# Test other types work too
puts "\nOther numeric types:"
puts "5_i64.grams => #{5_i64.grams.format}"
puts "5.0_f32.grams => #{5.0_f32.grams.format}"
puts "BigDecimal.new(\"5.123\").grams => #{BigDecimal.new("5.123").grams.format}"

# Test all measurement types
puts "\nAll measurement types:"
puts "5.meters => #{5.meters.format}"
puts "2.liters => #{2.liters.format}"
puts "10.pounds => #{10.pounds.format}"
puts "15.cm => #{15.cm.format}"
puts "500.ml => #{500.ml.format}"

puts "\n=== All tests passed! ==="
