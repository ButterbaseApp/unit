require "../src/unit"

# Weight conversions
puts "=== Weight Conversions ==="
weight_kg = Unit::Weight.new(2.5, Unit::Weight::Unit::Kilogram)
puts "Original: #{weight_kg}"

weight_g = weight_kg.convert_to(Unit::Weight::Unit::Gram)
puts "To grams: #{weight_g}"

weight_lb = weight_kg.to(Unit::Weight::Unit::Pound)
puts "To pounds: #{weight_lb}"

weight_oz = weight_lb.to(Unit::Weight::Unit::Ounce)
puts "Pounds to ounces: #{weight_oz}"

# Length conversions
puts "\n=== Length Conversions ==="
length_m = Unit::Length.new(10, Unit::Length::Unit::Meter)
puts "Original: #{length_m}"

length_ft = length_m.convert_to(Unit::Length::Unit::Foot)
puts "To feet: #{length_ft}"

length_in = length_ft.to(Unit::Length::Unit::Inch)
puts "Feet to inches: #{length_in}"

# Volume conversions (cooking focused)
puts "\n=== Volume Conversions (Cooking) ==="
volume_cups = Unit::Volume.new(2, Unit::Volume::Unit::Cup)
puts "Recipe calls for: #{volume_cups}"

volume_fl_oz = volume_cups.convert_to(Unit::Volume::Unit::FluidOunce)
puts "That's: #{volume_fl_oz}"

volume_ml = volume_cups.to(Unit::Volume::Unit::Milliliter)
puts "In metric: #{volume_ml}"

# Round-trip conversion to show precision
puts "\n=== Precision Test (Round-trip) ==="
original = Unit::Weight.new(1, Unit::Weight::Unit::Kilogram)
puts "Original: #{original}"

converted = original
  .convert_to(Unit::Weight::Unit::Gram)
  .convert_to(Unit::Weight::Unit::Pound)
  .convert_to(Unit::Weight::Unit::Ounce)
  .convert_to(Unit::Weight::Unit::Gram)
  .convert_to(Unit::Weight::Unit::Kilogram)

puts "After round-trip conversions: #{converted}"
puts "Values match: #{original.value == converted.value}"

# Cooking example
puts "\n=== Cooking Example ==="
recipe_cups = Unit::Volume.new(1.5, Unit::Volume::Unit::Cup)
puts "Recipe: #{recipe_cups} of flour"

# Convert to metric for precision
recipe_ml = recipe_cups.to(Unit::Volume::Unit::Milliliter)
puts "Precise measurement: #{recipe_ml}"

# Half the recipe
half_recipe = Unit::Volume.new(recipe_ml.value / 2, Unit::Volume::Unit::Milliliter)
half_recipe_cups = half_recipe.to(Unit::Volume::Unit::Cup)
puts "Half recipe: #{half_recipe_cups}"
