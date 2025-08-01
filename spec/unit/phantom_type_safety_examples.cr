# Phantom Type Safety Examples
# 
# This file demonstrates how phantom types in the Measurement class
# provide compile-time type safety. The examples below would cause
# compilation errors if uncommented.

require "../../src/unit/measurement"

# Define phantom type markers
struct Weight; end
struct Length; end
struct Temperature; end

enum WeightUnit
  Kilogram
  Gram
  Pound
end

enum LengthUnit
  Meter
  Centimeter
  Inch
end

enum TemperatureUnit
  Celsius
  Fahrenheit
  Kelvin
end

# Valid usage - same phantom types
def add_weights(w1 : Unit::Measurement(Weight, WeightUnit), w2 : Unit::Measurement(Weight, WeightUnit))
  # This would work for weight addition logic
  puts "Adding #{w1.value} #{w1.unit} + #{w2.value} #{w2.unit}"
end

# COMPILE-TIME SAFETY DEMONSTRATIONS
# The following code blocks would fail compilation if uncommented:

# Example 1: Cannot assign different phantom types
# weight = Unit::Measurement(Weight, WeightUnit).new(10, WeightUnit::Kilogram)
# length = Unit::Measurement(Length, LengthUnit).new(5, LengthUnit::Meter)
# weight = length  # Error: can't assign Measurement(Length, LengthUnit) to Measurement(Weight, WeightUnit)

# Example 2: Function parameters enforce phantom types
def process_weight(w : Unit::Measurement(Weight, WeightUnit))
  puts "Processing weight: #{w.value} #{w.unit}"
end

# weight = Unit::Measurement(Weight, WeightUnit).new(10, WeightUnit::Kilogram)
# length = Unit::Measurement(Length, LengthUnit).new(5, LengthUnit::Meter)
# process_weight(weight)  # ✅ Valid
# process_weight(length)  # ❌ Compile error: can't pass Length measurement to Weight function

# Example 3: Array type constraints
# weights = [] of Unit::Measurement(Weight, WeightUnit)
# weights << Unit::Measurement(Weight, WeightUnit).new(10, WeightUnit::Kilogram)  # ✅ Valid
# weights << Unit::Measurement(Length, LengthUnit).new(5, LengthUnit::Meter)     # ❌ Compile error

# Example 4: Variable type constraints
# weight_var : Unit::Measurement(Weight, WeightUnit)
# length_var : Unit::Measurement(Length, LengthUnit)
# weight_var = Unit::Measurement(Weight, WeightUnit).new(10, WeightUnit::Kilogram)   # ✅ Valid
# length_var = Unit::Measurement(Length, LengthUnit).new(5, LengthUnit::Meter)      # ✅ Valid
# weight_var = length_var  # ❌ Compile error: type mismatch
# length_var = weight_var  # ❌ Compile error: type mismatch

# Valid examples that compile successfully:
weight1 = Unit::Measurement(Weight, WeightUnit).new(10, WeightUnit::Kilogram)
weight2 = Unit::Measurement(Weight, WeightUnit).new(5, WeightUnit::Gram)
length1 = Unit::Measurement(Length, LengthUnit).new(100, LengthUnit::Centimeter)
temp1 = Unit::Measurement(Temperature, TemperatureUnit).new(25, TemperatureUnit::Celsius)

# Same phantom types can be used together
add_weights(weight1, weight2)

puts "✅ Phantom type safety examples compiled successfully!"
puts "✅ All type constraints are enforced at compile time!"