#!/usr/bin/env crystal

# Test script to verify Avram integration compiles correctly
# This doesn't run actual database operations, just verifies the code compiles

require "./src/unit"
require "./src/unit/integrations/avram"

# Test that we can include the modules
class TestModel
  include Unit::Avram::ColumnExtensions
  
  property weight_value : Float64?
  property weight_unit : String?
  
  measurement_column :weight, Weight
end

# Test that types work
def test_types
  # Test serialization
  weight = Unit::Weight.new(10, :kilogram)
  json = Unit::Avram::WeightType.to_db(weight)
  puts "Serialized weight: #{json}"
  
  # Test deserialization
  parsed = Unit::Avram::WeightType.parse(json)
  puts "Parsed weight: #{parsed}"
  
  # Test nil handling
  nil_json = Unit::Avram::WeightType.to_db(nil)
  puts "Nil serialization: #{nil_json.inspect}"
end

# Test model usage
def test_model
  model = TestModel.new
  model.weight = Unit::Weight.new(25.5, :kilogram)
  
  puts "Model weight value: #{model.weight_value}"
  puts "Model weight unit: #{model.weight_unit}"
  puts "Model weight: #{model.weight}"
  puts "Weight in pounds: #{model.weight_in(:pound)}"
end

# Test validation macros compile
class TestOperation
  include Unit::Avram::ValidationExtensions
  
  validate_measurement_positive :weight
  validate_measurement_range :length, 
    Unit::Length.new(1, :meter), 
    Unit::Length.new(100, :meter)
  
  def before_save
    # Dummy implementation
  end
end

puts "Testing Unit Avram Integration..."
puts "================================="
test_types
puts
test_model
puts
puts "✓ All tests compiled successfully!"
puts "Note: This is a compilation test only. Actual database operations require a configured Avram database."