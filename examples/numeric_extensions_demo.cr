#!/usr/bin/env crystal

# Demo of the new numeric extensions for easy measurement creation
#
# This example shows how the new numeric extensions allow for more intuitive
# measurement creation using methods like 5.grams and 1.2.kg instead of
# the more verbose Unit::Weight.new(5, :gram).

require "../src/unit"
require "../src/unit/extensions"

puts "=== Numeric Extensions Demo ==="
puts

# Weight examples
puts "Weight Examples:"
weight1 = 5.grams
puts "5.grams => #{weight1}"
puts "  Formatted: #{weight1.format}"
puts "  To kg: #{weight1.convert_to(:kilogram).format}"

weight2 = 1.2.kg
puts "\n1.2.kg => #{weight2}"
puts "  Formatted: #{weight2.format}"
puts "  To pounds: #{weight2.convert_to(:pound).format}"

weight3 = 500.mg
puts "\n500.mg => #{weight3}"
puts "  Formatted: #{weight3.format}"
puts "  To grams: #{weight3.convert_to(:gram).format}"

weight4 = 2.pounds
puts "\n2.pounds => #{weight4}"
puts "  Formatted: #{weight4.format}"
puts "  To kg: #{weight4.convert_to(:kilogram).format}"

# Length examples
puts "\nLength Examples:"
length1 = 5.meters
puts "5.meters => #{length1}"
puts "  Formatted: #{length1.format}"
puts "  To feet: #{length1.convert_to(:foot).format}"

length2 = 1.2.km
puts "\n1.2.km => #{length2}"
puts "  Formatted: #{length2.format}"
puts "  To miles: #{length2.convert_to(:mile).format}"

length3 = 500.mm
puts "\n500.mm => #{length3}"
puts "  Formatted: #{length3.format}"
puts "  To inches: #{length3.convert_to(:inch).format}"

length4 = 2.feet
puts "\n2.feet => #{length4}"
puts "  Formatted: #{length4.format}"
puts "  To meters: #{length4.convert_to(:meter).format}"

# Volume examples
puts "\nVolume Examples:"
volume1 = 5.liters
puts "5.liters => #{volume1}"
puts "  Formatted: #{volume1.format}"
puts "  To gallons: #{volume1.convert_to(:gallon).format}"

volume2 = 1.2.ml
puts "\n1.2.ml => #{volume2}"
puts "  Formatted: #{volume2.format}"
puts "  To liters: #{volume2.convert_to(:liter).format}"

volume3 = 500.cups
puts "\n500.cups => #{volume3}"
puts "  Formatted: #{volume3.format}"
puts "  To liters: #{volume3.convert_to(:liter).format}"

volume4 = 2.gallons
puts "\n2.gallons => #{volume4}"
puts "  Formatted: #{volume4.format}"
puts "  To liters: #{volume4.convert_to(:liter).format}"

# Arithmetic with convenient syntax
puts "\nArithmetic Examples:"
total_weight = 5.grams + 2.kg + 500.mg
puts "5.grams + 2.kg + 500.mg = #{total_weight.format}"

total_length = 1.meter + 50.cm + 25.mm
puts "1.meter + 50.cm + 25.mm = #{total_length.format}"

total_volume = 1.liter + 500.ml + 2.cups
puts "1.liter + 500.ml + 2.cups = #{total_volume.format}"

# BigDecimal support
puts "\nBigDecimal Examples:"
precise_weight = BigDecimal.new("3.14159").grams
puts "BigDecimal.new(\"3.14159\").grams = #{precise_weight.format}"

precise_length = BigDecimal.new("2.71828").meters
puts "BigDecimal.new(\"2.71828\").meters = #{precise_length.format}"

puts "\n=== Demo Complete ==="
