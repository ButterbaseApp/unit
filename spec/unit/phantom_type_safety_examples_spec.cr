# Phantom Type Safety Examples
#
# This file demonstrates how phantom types in the Measurement class
# provide compile-time type safety. The examples below would cause
# compilation errors if uncommented.

require "../../src/unit/measurement"

# Define phantom type markers for phantom type examples
struct PhantomWeight; end

struct PhantomLength; end

struct PhantomTemperature; end

enum PhantomWeightUnit
  Kilogram
  Gram
  Pound
end

enum PhantomLengthUnit
  Meter
  Centimeter
  Inch
end

enum PhantomTemperatureUnit
  Celsius
  Fahrenheit
  Kelvin
end

# Valid usage - same phantom types
def add_weights(w1 : Unit::Measurement(PhantomWeight, PhantomWeightUnit), w2 : Unit::Measurement(PhantomWeight, PhantomWeightUnit))
  # This would work for weight addition logic
  puts "Adding #{w1.value} #{w1.unit} + #{w2.value} #{w2.unit}"
end

# COMPILE-TIME SAFETY DEMONSTRATIONS
# The following code blocks would fail compilation if uncommented:

# Example 1: Cannot assign different phantom types
# weight = Unit::Measurement(PhantomWeight, PhantomWeightUnit).new(10, PhantomWeightUnit::Kilogram)
# length = Unit::Measurement(PhantomLength, PhantomLengthUnit).new(5, PhantomLengthUnit::Meter)
# weight = length  # Error: can't assign Measurement(PhantomLength, PhantomLengthUnit) to Measurement(PhantomWeight, PhantomWeightUnit)

# Example 2: Function parameters enforce phantom types
def process_weight(w : Unit::Measurement(PhantomWeight, PhantomWeightUnit))
  puts "Processing weight: #{w.value} #{w.unit}"
end

# weight = Unit::Measurement(PhantomWeight, PhantomWeightUnit).new(10, PhantomWeightUnit::Kilogram)
# length = Unit::Measurement(PhantomLength, PhantomLengthUnit).new(5, PhantomLengthUnit::Meter)
# process_weight(weight)  # ✅ Valid
# process_weight(length)  # ❌ Compile error: can't pass Length measurement to Weight function

# Example 3: Array type constraints
# weights = [] of Unit::Measurement(PhantomWeight, PhantomWeightUnit)
# weights << Unit::Measurement(PhantomWeight, PhantomWeightUnit).new(10, PhantomWeightUnit::Kilogram)  # ✅ Valid
# weights << Unit::Measurement(PhantomLength, PhantomLengthUnit).new(5, PhantomLengthUnit::Meter)     # ❌ Compile error

# Example 4: Variable type constraints
# weight_var : Unit::Measurement(PhantomWeight, PhantomWeightUnit)
# length_var : Unit::Measurement(PhantomLength, PhantomLengthUnit)
# weight_var = Unit::Measurement(PhantomWeight, PhantomWeightUnit).new(10, PhantomWeightUnit::Kilogram)   # ✅ Valid
# length_var = Unit::Measurement(PhantomLength, PhantomLengthUnit).new(5, PhantomLengthUnit::Meter)      # ✅ Valid
# weight_var = length_var  # ❌ Compile error: type mismatch
# length_var = weight_var  # ❌ Compile error: type mismatch

# Valid examples that compile successfully:
weight1 = Unit::Measurement(PhantomWeight, PhantomWeightUnit).new(10, PhantomWeightUnit::Kilogram)
weight2 = Unit::Measurement(PhantomWeight, PhantomWeightUnit).new(5, PhantomWeightUnit::Gram)
length1 = Unit::Measurement(PhantomLength, PhantomLengthUnit).new(100, PhantomLengthUnit::Centimeter)
temp1 = Unit::Measurement(PhantomTemperature, PhantomTemperatureUnit).new(25, PhantomTemperatureUnit::Celsius)

# Use the variables to avoid unused assignment warnings
puts "Weight 1: #{weight1.value} #{weight1.unit}"
puts "Weight 2: #{weight2.value} #{weight2.unit}"
puts "Length 1: #{length1.value} #{length1.unit}"
puts "Temperature 1: #{temp1.value} #{temp1.unit}"

# Same phantom types can be used together
add_weights(weight1, weight2)

puts "✅ Phantom type safety examples compiled successfully!"
puts "✅ All type constraints are enforced at compile time!"
