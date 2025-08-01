require "../src/unit"

# Demonstration of the new formatting capabilities
puts "=== Unit Formatting Demo ==="
puts

# Create some example measurements
weight = Unit::Weight.new(10.5, Unit::Weight::Unit::Kilogram)
length = Unit::Length.new(5.75, Unit::Length::Unit::Meter)
volume = Unit::Volume.new(2.5, Unit::Volume::Unit::Liter)

puts "=== Default to_s (backward compatible) ==="
puts "Weight: #{weight}"
puts "Length: #{length}"
puts "Volume: #{volume}"
puts

puts "=== Format with precision control ==="
puts "Weight (0 decimals): #{weight.format(precision: 0)}"
puts "Weight (1 decimal):  #{weight.format(precision: 1)}"
puts "Weight (3 decimals): #{weight.format(precision: 3)}"
puts

puts "=== Format with unit styles ==="
puts "Weight (long):  #{weight.format(unit_format: :long)}"
puts "Weight (short): #{weight.format(unit_format: :short)}"
puts "Length (short): #{length.format(unit_format: :short)}"
puts "Volume (short): #{volume.format(unit_format: :short)}"
puts

puts "=== Combined formatting options ==="
puts "Weight (1 decimal, short): #{weight.format(precision: 1, unit_format: :short)}"
puts "Length (0 decimals, short): #{length.format(precision: 0, unit_format: :short)}"
puts

puts "=== Humanized output ==="
puts "1 kilogram:    #{Unit::Weight.new(1, Unit::Weight::Unit::Kilogram).humanize}"
puts "0 kilograms:   #{Unit::Weight.new(0, Unit::Weight::Unit::Kilogram).humanize}"
puts "2.5 kilograms: #{Unit::Weight.new(2.5, Unit::Weight::Unit::Kilogram).humanize}"
puts "1 meter:       #{Unit::Length.new(1, Unit::Length::Unit::Meter).humanize}"
puts "3 meters:      #{Unit::Length.new(3, Unit::Length::Unit::Meter).humanize}"
puts "1 fluid ounce: #{Unit::Volume.new(1, Unit::Volume::Unit::FluidOunce).humanize}"
puts "2 fluid ounces: #{Unit::Volume.new(2, Unit::Volume::Unit::FluidOunce).humanize}"
puts

puts "=== Edge cases ==="
puts "Negative value: #{Unit::Weight.new(-1.5, Unit::Weight::Unit::Kilogram).humanize}"
puts "Zero value:     #{Unit::Weight.new(0, Unit::Weight::Unit::Kilogram).format(precision: 1)}"
puts "Large value:    #{Unit::Weight.new(12345.6789, Unit::Weight::Unit::Gram).format(precision: 2, unit_format: :short)}"
puts

puts "=== Different measurement types with formatting ==="
measurements = [
  Unit::Weight.new(2.2, Unit::Weight::Unit::Pound),
  Unit::Length.new(12, Unit::Length::Unit::Inch),
  Unit::Volume.new(1, Unit::Volume::Unit::Cup),
]

measurements.each do |measurement|
  puts "#{measurement.class.name.split("::").last}: #{measurement.format(unit_format: :short)} | #{measurement.humanize}"
end
