module Unit
  # Arithmetic operations module for measurement calculations
  #
  # Provides mathematical operations between measurements of the same type.
  # All operations maintain immutability by returning new instances and
  # preserve precision using BigDecimal arithmetic.
  #
  # Operations automatically handle unit conversion when needed, with the
  # result maintaining the unit of the left operand.
  #
  # Example:
  # ```
  # weight1 = Weight.new(5, Weight::Unit::Kilogram)
  # weight2 = Weight.new(500, Weight::Unit::Gram)
  # result = weight1 + weight2 # => 1.5 kg
  # ```
  module Arithmetic
    # Adds two measurements together
    #
    # If the measurements have different units, the right operand is
    # converted to match the left operand's unit before addition.
    # The result maintains the left operand's unit.
    #
    # Returns a new measurement instance, preserving immutability.
    #
    # Example:
    # ```
    # weight1 = Weight.new(1, Weight::Unit::Kilogram)
    # weight2 = Weight.new(500, Weight::Unit::Gram)
    # result = weight1 + weight2 # => 1.5 kg
    # ```
    def +(other : self) : self
      if @unit == other.unit
        self.class.new(@value + other.value, @unit)
      else
        converted = other.convert_to(@unit)
        self.class.new(@value + converted.value, @unit)
      end
    end

    # Subtracts one measurement from another
    #
    # If the measurements have different units, the right operand is
    # converted to match the left operand's unit before subtraction.
    # The result maintains the left operand's unit.
    #
    # Returns a new measurement instance, preserving immutability.
    # Negative results are supported.
    #
    # Example:
    # ```
    # weight1 = Weight.new(2, Weight::Unit::Kilogram)
    # weight2 = Weight.new(500, Weight::Unit::Gram)
    # result = weight1 - weight2 # => 1.5 kg
    # ```
    def -(other : self) : self
      if @unit == other.unit
        self.class.new(@value - other.value, @unit)
      else
        converted = other.convert_to(@unit)
        self.class.new(@value - converted.value, @unit)
      end
    end

    # Multiplies a measurement by a scalar value
    #
    # Scales the measurement value while preserving the unit.
    # Accepts any numeric type and converts to BigDecimal for precision.
    #
    # Returns a new measurement instance, preserving immutability.
    #
    # Example:
    # ```
    # weight = Weight.new(5, Weight::Unit::Kilogram)
    # result = weight * 2.5 # => 12.5 kg
    # ```
    def *(scalar : Number) : self
      self.class.new(@value * BigDecimal.new(scalar.to_s), @unit)
    end

    # Divides a measurement by a scalar value
    #
    # Scales the measurement value by division while preserving the unit.
    # Accepts any numeric type and converts to BigDecimal for precision.
    #
    # Returns a new measurement instance, preserving immutability.
    # Raises ArgumentError if scalar is zero.
    #
    # Example:
    # ```
    # weight = Weight.new(10, Weight::Unit::Kilogram)
    # result = weight / 2 # => 5 kg
    # ```
    def /(scalar : Number) : self
      raise ArgumentError.new("Cannot divide by zero") if scalar == 0
      self.class.new(@value / BigDecimal.new(scalar.to_s), @unit)
    end
  end
end
