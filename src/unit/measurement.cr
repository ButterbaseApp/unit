require "big"
require "./arithmetic"
require "./conversion"
require "./formatter"

module Unit
  # Generic measurement class with phantom types for compile-time type safety
  #
  # T represents the measurement type (Weight, Length, etc.)
  # U represents the unit enum type
  #
  # Examples:
  #   Measurement(Weight, WeightUnit).new(10.5, WeightUnit::Kilogram)
  #   Measurement(Length, LengthUnit).new(5, LengthUnit::Meter)
  class Measurement(T, U)
    include Arithmetic
    include Conversion
    include Formatter
    
    # Value stored as BigDecimal for precision
    getter value : BigDecimal
    
    # Unit of measurement
    getter unit : U
    
    # Creates a new measurement with the given value and unit
    #
    # The value is converted to BigDecimal for precision preservation
    # Supports Int32, Int64, Float32, Float64, BigDecimal, BigRational input
    #
    # Raises ArgumentError for invalid values like NaN or Infinity
    def initialize(value : Number, @unit : U)
      # Handle Float edge cases before conversion
      if value.is_a?(Float32) || value.is_a?(Float64)
        raise ArgumentError.new("Value cannot be NaN") if value.nan?
        raise ArgumentError.new("Value cannot be infinite") if value.infinite?
      end
      
      # Handle BigRational which needs special conversion
      @value = case value
               when BigRational
                 BigDecimal.new(value.to_f.to_s)
               else
                 BigDecimal.new(value.to_s)
               end
      validate_value!
    end
    
    
    # Returns a detailed string representation for debugging
    #
    # Shows type parameters and internal structure
    def inspect(io : IO) : Nil
      io << "Measurement(" << T << ", " << U << ")"
      io << "(" << @value << ", " << @unit << ")"
    end
    
    # Equality comparison based on value and unit
    #
    # Two measurements are equal if they have the same value and unit
    # Note: This only compares measurements of the same phantom type
    def ==(other : Measurement(T, U)) : Bool
      @value == other.value && @unit == other.unit
    end
    
    # Hash function for use in Hash collections
    #
    # Based on value and unit for consistency with equality
    def hash(hasher)
      hasher = @value.hash(hasher)
      hasher = @unit.hash(hasher)
      hasher
    end
    
    private def validate_value!
      # Crystal's type system prevents nil values, but check for edge cases
      
      # Check for zero value in string representation which might indicate conversion issues
      value_str = @value.to_s
      
      # Validate that the BigDecimal conversion was successful
      # BigDecimal should never be in an invalid state after successful construction
      raise ArgumentError.new("Invalid measurement value") if value_str.empty?
      
      # Optional: Add domain-specific validation rules
      # For example, physical measurements might want to reject negative values
      # This is left flexible for subclasses or specific measurement types
    end
  end
end