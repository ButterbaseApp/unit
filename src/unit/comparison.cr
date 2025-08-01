module Unit
  # Comparison operations module for measurement comparisons
  #
  # Provides comparison operations between measurements of the same type.
  # Operations automatically handle unit conversion when needed for accurate
  # comparisons across different units.
  #
  # The comparison is based on the actual quantity represented by the
  # measurement, not the raw numeric value and unit combination.
  #
  # Example:
  # ```
  # weight1 = Weight.new(1, Weight::Unit::Kilogram)
  # weight2 = Weight.new(1000, Weight::Unit::Gram)
  # weight1 == weight2 # => true (equivalent quantities)
  # ```
  module Comparison
    # Spaceship operator for ordering comparisons
    #
    # Compares two measurements and returns:
    # - -1 if this measurement is less than the other
    # - 0 if measurements are equal
    # - 1 if this measurement is greater than the other
    #
    # If measurements have different units, the other measurement is
    # converted to this measurement's unit before comparison.
    #
    # This method enables all Comparable operations (<, >, <=, >=, between?)
    #
    # Example:
    # ```
    # weight1 = Weight.new(1, Weight::Unit::Kilogram)
    # weight2 = Weight.new(500, Weight::Unit::Gram)
    # weight1 <=> weight2 # => 1 (1kg > 500g)
    # ```
    def <=>(other : self) : Int32
      if @unit == other.unit
        @value <=> other.value
      else
        converted = other.convert_to(@unit)
        @value <=> converted.value
      end
    end

    # Equality comparison with automatic unit conversion
    #
    # Returns true if both measurements represent the same quantity,
    # regardless of their units. Uses BigDecimal comparison for precision.
    #
    # If measurements have different units, one is converted to match
    # the other before comparison.
    #
    # Example:
    # ```
    # weight1 = Weight.new(1, Weight::Unit::Kilogram)
    # weight2 = Weight.new(1000, Weight::Unit::Gram)
    # weight1 == weight2 # => true
    # ```
    def ==(other : self) : Bool
      if @unit == other.unit
        @value == other.value
      else
        converted = other.convert_to(@unit)
        @value == converted.value
      end
    end

    # Hash method ensuring equivalent measurements have equal hashes
    #
    # Converts the measurement to its base unit value before hashing to ensure
    # that equivalent measurements in different units produce the same hash.
    # This is crucial for using measurements as Hash keys or in Set collections.
    #
    # The hash combines the measurement type name and the base unit value
    # to create a unique, reproducible hash value.
    #
    # Example:
    # ```
    # weight1 = Weight.new(1, Weight::Unit::Kilogram)
    # weight2 = Weight.new(1000, Weight::Unit::Gram)
    # weight1.hash == weight2.hash # => true
    # ```
    def hash(hasher)
      # Convert to base unit to ensure equivalent measurements hash equally
      base_value = to_base_unit_value
      hasher = self.class.name.hash(hasher)
      hasher = base_value.hash(hasher)
      hasher
    end
  end
end
