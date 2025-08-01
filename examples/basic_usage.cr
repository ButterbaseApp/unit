require "../src/unit"

# Basic Usage Examples for the Unit Library
# This demonstrates core functionality and common use cases

puts "=== Creating Measurements ==="

# Different ways to create measurements
weight1 = Unit::Weight.new(5.5, :kilogram)
weight2 = Unit::Weight.new(10, Unit::Weight::Unit::Pound)
weight3 = Unit::Weight.new(BigDecimal.new("2.54321"), :kilogram)

puts "Using symbol: #{weight1}"
puts "Using enum: #{weight2}"
puts "Using BigDecimal: #{weight3}"

puts "\n=== Basic Conversions ==="

# Convert between units
kg_weight = Unit::Weight.new(1, :kilogram)
puts "1 kilogram = #{kg_weight.to(:gram)} grams"
puts "1 kilogram = #{kg_weight.to(:pound)} pounds"
puts "1 kilogram = #{kg_weight.to(:ounce)} ounces"

# Length conversions
meter = Unit::Length.new(1, :meter)
puts "\n1 meter = #{meter.to(:centimeter)} centimeters"
puts "1 meter = #{meter.to(:foot)} feet"
puts "1 meter = #{meter.to(:inch)} inches"

puts "\n=== Arithmetic Operations ==="

# Addition with automatic conversion
weight_a = Unit::Weight.new(5, :kilogram)
weight_b = Unit::Weight.new(10, :pound)
total_weight = weight_a + weight_b
puts "5 kg + 10 lb = #{total_weight} (in kg)"

# Subtraction
length_a = Unit::Length.new(2, :meter)
length_b = Unit::Length.new(50, :centimeter)
difference = length_a - length_b
puts "2 m - 50 cm = #{difference}"

# Multiplication and division by scalars
doubled = weight_a * 2
puts "5 kg × 2 = #{doubled}"

halved = length_a / 2
puts "2 m ÷ 2 = #{halved}"

puts "\n=== Comparisons ==="

# Compare measurements with different units
heavy = Unit::Weight.new(100, :kilogram)
light = Unit::Weight.new(50, :pound)

puts "100 kg > 50 lb? #{heavy > light}"
puts "100 kg < 50 lb? #{heavy < light}"

# Equality comparison
kg1 = Unit::Weight.new(1, :kilogram)
g1000 = Unit::Weight.new(1000, :gram)
puts "1 kg == 1000 g? #{kg1 == g1000} (different units, same mass)"

# Note: For equality with unit conversion, you need to convert first
puts "1 kg == 1000 g (converted)? #{kg1.value == g1000.to(:kilogram).value}"

puts "\n=== Sorting ==="

# Measurements sort by actual value, not numeric value
weights = [
  Unit::Weight.new(500, :gram),
  Unit::Weight.new(2, :kilogram),
  Unit::Weight.new(1, :pound),
  Unit::Weight.new(100, :gram),
]

puts "Unsorted weights:"
weights.each { |w| puts "  #{w}" }

sorted = weights.sort
puts "\nSorted by actual weight:"
sorted.each { |w| puts "  #{w}" }

puts "\n=== Working with Precision ==="

# BigDecimal ensures precision
precise_weight = Unit::Weight.new(BigDecimal.new("3.14159265358979"), :kilogram)
puts "Precise weight: #{precise_weight}"
puts "Value type: #{precise_weight.value.class}"
puts "Converted: #{precise_weight.to(:gram)}"

# Calculations maintain precision
result = precise_weight * BigDecimal.new("2.71828182845905")
puts "Precise calculation: #{result}"

puts "\n=== Type Safety Examples ==="

# These examples would not compile (commented out)
weight = Unit::Weight.new(10, :kilogram)
length = Unit::Length.new(5, :meter)

# This would cause a compile error:
# total = weight + length  # Error: can't add Weight to Length

# This would also fail:
# comparison = weight > length  # Error: can't compare Weight to Length

puts "Type safety prevents mixing incompatible measurements!"

puts "\n=== Practical Examples ==="

# Example 1: BMI Calculation
puts "\nBMI Calculation:"
weight = Unit::Weight.new(70, :kilogram)
height = Unit::Length.new(175, :centimeter)

# Convert to standard units for BMI (kg and meters)
weight_kg = weight.to(:kilogram).value
height_m = height.to(:meter).value

bmi = weight_kg / (height_m * height_m)
puts "Weight: #{weight}"
puts "Height: #{height}"
puts "BMI: #{bmi.round(2)}"

# Example 2: Shipping calculations
puts "\nShipping Package:"
package_weight = Unit::Weight.new(2.5, :kilogram)
package_length = Unit::Length.new(30, :centimeter)
package_width = Unit::Length.new(20, :centimeter)
package_height = Unit::Length.new(15, :centimeter)

puts "Package weight: #{package_weight.to(:pound).format(precision: 1)}"
puts "Dimensions: #{package_length.to(:inch).format(precision: 0)}\" × " \
     "#{package_width.to(:inch).format(precision: 0)}\" × " \
     "#{package_height.to(:inch).format(precision: 0)}\""

# Example 3: Recipe scaling
puts "\nRecipe Scaling:"
original_flour = Unit::Volume.new(2, :cup)
original_milk = Unit::Volume.new(1.5, :cup)
scale_factor = 0.5 # Make half the recipe

scaled_flour = Unit::Volume.new(original_flour.value * scale_factor, :cup)
scaled_milk = Unit::Volume.new(original_milk.value * scale_factor, :cup)

puts "Original recipe:"
puts "  Flour: #{original_flour}"
puts "  Milk: #{original_milk}"
puts "Scaled recipe (#{scale_factor}x):"
puts "  Flour: #{scaled_flour}"
puts "  Milk: #{scaled_milk}"

puts "\n=== Summary ==="
puts "The Unit library provides:"
puts "- Type-safe measurements"
puts "- Automatic unit conversions"
puts "- Arithmetic operations"
puts "- High precision with BigDecimal"
puts "- Compile-time safety"
