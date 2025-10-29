#!/usr/bin/env crystal

require "../src/unit"
require "../src/unit/extensions"

# Density Conversion Demonstration
#
# This example demonstrates the new density conversion functionality that allows
# you to convert between weight and volume measurements using density values.
#
# Run with: crystal run examples/density_demo.cr

puts "=== Density Conversion Demo ==="
puts

# Create some basic density measurements
puts "1. Creating Density Measurements"
puts "-" * 40

water_density = 1.0.g_per_ml
oil_density = 0.92.g_per_ml
honey_density = 1.42.g_per_cc
flour_density = 0.593.g_per_ml
mercury_density = 13.534.g_per_cc

puts "Water density: #{water_density.format(precision: 3)}"
puts "Vegetable oil: #{oil_density.format(precision: 3)}"
puts "Honey: #{honey_density.format(precision: 3)}"
puts "Flour: #{flour_density.format(precision: 3)}"
puts "Mercury: #{mercury_density.format(precision: 3)}"
puts

# Common material densities
puts "2. Common Material Densities"
puts "-" * 40

water_20c = Unit::Density.new(0.9982, :gram_per_milliliter)
milk = Unit::Density.new(1.030, :gram_per_milliliter)
butter = Unit::Density.new(0.911, :gram_per_milliliter)
flour_common = Unit::Density.new(0.593, :gram_per_milliliter)
sugar_granulated = Unit::Density.new(0.850, :gram_per_milliliter)

puts "Water (20°C): #{water_20c.format(precision: 3)}"
puts "Whole milk: #{milk.format(precision: 3)}"
puts "Butter: #{butter.format(precision: 3)}"
puts "All-purpose flour: #{flour_common.format(precision: 3)}"
puts "Granulated sugar: #{sugar_granulated.format(precision: 3)}"
puts

# Density conversions
puts "3. Density Unit Conversions"
puts "-" * 40

density_lb_per_gal = water_density.convert_to(:lb_per_gal)
puts "Water density in lb/gal: #{density_lb_per_gal.format(precision: 3)}"

density_kg_per_m3 = water_density.convert_to(:kg_per_m3)
puts "Water density in kg/m³: #{density_kg_per_m3.format(precision: 1)}"

density_lb_per_ft3 = mercury_density.convert_to(:lb_per_ft3)
puts "Mercury density in lb/ft³: #{density_lb_per_ft3.format(precision: 1)}"
puts

# Weight to Volume conversions
puts "4. Weight to Volume Conversions"
puts "-" * 40

# Using Density objects
puts "Using Density objects:"
flour_weight = 200.grams
flour_volume = flour_weight.to_volume(flour_density)
puts "200g flour occupies: #{flour_volume.format(precision: 1)}"

honey_weight = 500.grams
honey_volume = honey_weight.to_volume(honey_density)
puts "500g honey occupies: #{honey_volume.format(precision: 1)}"

# Using overloaded methods (value + unit)
puts "\nUsing value + unit (no Density object needed):"
oil_weight = 250.grams
oil_volume = oil_weight.to_volume(0.92, :g_per_ml)
puts "250g oil occupies: #{oil_volume.format(precision: 1)}"

sugar_weight = 1.kilogram
sugar_volume = sugar_weight.to_volume(0.85, :gram_per_milliliter)
puts "1kg sugar occupies: #{sugar_volume.format(precision: 0)}"

# Using explicit naming for clarity
puts "\nUsing explicit method names:"
butter_weight = 1.pound
butter_density = Unit::Density.new(0.911, :gram_per_milliliter)
butter_volume = butter_weight.volume_given(butter_density)
puts "1lb butter occupies: #{butter_volume.format(precision: 2)}"
puts

# Volume to Weight conversions
puts "5. Volume to Weight Conversions"
puts "-" * 40

# Using Density objects
puts "Using Density objects:"
milk_volume = 250.milliliters
milk_density = Unit::Density.new(1.030, :gram_per_milliliter)
milk_weight = milk_volume.to_weight(milk_density)
puts "250mL milk weighs: #{milk_weight.format(precision: 1)}"

mercury_volume = 100.milliliters
mercury_weight = mercury_volume.to_weight(mercury_density)
puts "100mL mercury weighs: #{mercury_weight.format(precision: 1)}"

# Using overloaded methods (value + unit)
puts "\nUsing value + unit (no Density object needed):"
water_volume = 1.liter
water_weight = water_volume.to_weight(1.0, :gram_per_milliliter)
puts "1L water weighs: #{water_weight.format(precision: 1)}"

juice_volume = 1.cup
juice_weight = juice_volume.to_weight(1.03, :g_per_ml)
puts "1 cup juice weighs: #{juice_weight.format(precision: 1)}"

# Using explicit naming for clarity
puts "\nUsing explicit method names:"
beer_volume = 16.fluid_ounces
beer_weight = beer_volume.weight_given(1.01, :g_per_ml) # Typical beer density
puts "16 fl oz beer weighs: #{beer_weight.format(precision: 1)}"
puts

# Practical cooking examples
puts "6. Practical Cooking Examples"
puts "-" * 40

# Recipe scaling
puts "Recipe Scaling Example:"
original_recipe = {
  flour: 2.cups,
  sugar: 1.cup,
  milk:  0.5.cup,
}

puts "Original recipe weights:"

# Convert recipe volumes to weights using densities
flour_weight = original_recipe[:flour].to_weight(flour_density)
sugar_weight = original_recipe[:sugar].to_weight(sugar_granulated)
milk_weight = original_recipe[:milk].to_weight(milk)

puts "  Flour: #{flour_weight.format(precision: 0)}"
puts "  Sugar: #{sugar_weight.format(precision: 0)}"
puts "  Milk: #{milk_weight.format(precision: 0)}"

# Scale recipe by 1.5x
scale_factor = 1.5
scaled_flour_weight = flour_weight * scale_factor
scaled_sugar_weight = sugar_weight * scale_factor
scaled_milk_weight = milk_weight * scale_factor

puts "\nScaled recipe (1.5x) weights:"
puts "  Flour: #{scaled_flour_weight.format(precision: 0)}"
puts "  Sugar: #{scaled_sugar_weight.format(precision: 0)}"
puts "  Milk: #{scaled_milk_weight.format(precision: 0)}"

# Convert back to volumes for measuring
puts "\nScaled recipe volumes:"
scaled_flour_volume = scaled_flour_weight.to_volume(flour_density)
scaled_sugar_volume = scaled_sugar_weight.to_volume(sugar_granulated)
scaled_milk_volume = scaled_milk_weight.to_volume(milk)

puts "  Flour: #{scaled_flour_volume.format(precision: 2)}"
puts "  Sugar: #{scaled_sugar_volume.format(precision: 2)}"
puts "  Milk: #{scaled_milk_volume.format(precision: 2)}"
puts

# Scientific calculations
puts "7. Scientific Calculations"
puts "-" * 40

# Calculate if an object will float
puts "Buoyancy Calculation:"
wood_volume = Unit::Volume.new(1000, :milliliter)                  # 1000 mL = 1000 cm³
wood_density = Unit::Density.new(0.75, :gram_per_cubic_centimeter) # Oak wood
wood_weight = wood_volume.to_weight(wood_density)

water_density = Unit::Density.new(1.0, :gram_per_milliliter)
water_weight_displaced = wood_volume.to_weight(water_density)

puts "Wood block (1000 cm³):"
puts "  Weight: #{wood_weight.format(precision: 1)}"
puts "  Water displaced: #{water_weight_displaced.format(precision: 1)}"

if wood_weight < water_weight_displaced
  puts "  Result: WOOD FLOATS ✅"
else
  puts "  Result: WOOD SINKS ❌"
end

# Mercury comparison
mercury_volume = Unit::Volume.new(100, :milliliter)
mercury_weight = mercury_volume.to_weight(mercury_density)
water_weight_displaced_mercury = mercury_volume.to_weight(water_density)

puts "\nMercury block (100 cm³):"
puts "  Weight: #{mercury_weight.format(precision: 1)}"
puts "  Water displaced: #{water_weight_displaced_mercury.format(precision: 1)}"

puts "  Result: Mercury is #{(mercury_weight.value / water_weight_displaced_mercury.value).round(1)}x heavier than water"
puts

# International units example
puts "8. International Unit Examples"
puts "-" * 40

# Convert between different systems
puts "International Recipe Conversion:"
us_butter_weight = Unit::Weight.new(113, :gram) # ~1 stick butter
us_butter_volume_ml = us_butter_weight.to_volume(butter)
us_butter_volume_cups = us_butter_volume_ml.convert_to(:cup)

puts "1 stick butter (US):"
puts "  Weight: #{us_butter_weight.format(precision: 0)}"
puts "  Volume: #{us_butter_volume_cups.format(precision: 3)} cups"

# Metric conversion
european_butter = Unit::Weight.new(100, :gram)
european_butter_volume = european_butter.to_volume(butter)

puts "100g butter (European):"
puts "  Volume: #{european_butter_volume.format(precision: 1)}"
puts

# String parsing examples
puts "9. String Parsing Examples"
puts "-" * 40

begin
  parsed_density = Unit::Parser.parse(Unit::Density, "1.0 g/mL")
  puts "Parsed density: #{parsed_density.format(precision: 3)}"

  parsed_density2 = Unit::Parser.parse(Unit::Density, "62.4 lb/ft³")
  puts "Parsed density: #{parsed_density2.format(precision: 3)}"

  parsed_density3 = Unit::Parser.parse(Unit::Density, "0.92 g/cm³")
  puts "Parsed density: #{parsed_density3.format(precision: 3)}"
rescue ex
  puts "Parsing error: #{ex.message}"
end
puts

puts "=== Demo Complete ==="
puts "Key takeaways:"
puts "• Use to_volume(density) and to_weight(density) for conversions"
puts "• Both Density objects and value+unit pairs are supported"
puts "• Use volume_given() and weight_given() for more explicit naming"
puts "• Create custom density objects for any material"
puts "• Supports both metric and imperial units with precise conversions"
