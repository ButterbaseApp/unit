require "big"

module Unit
  # Unit conversion functionality for measurements
  #
  # This module provides the core conversion mechanism for all measurement types.
  # It uses a two-step conversion process through a base unit to ensure accuracy
  # and consistency across all unit conversions.
  #
  # ## Conversion Process
  #
  # 1. Convert the source value to the base unit (e.g., any weight to grams)
  # 2. Convert from the base unit to the target unit
  #
  # This approach minimizes rounding errors and ensures all conversions follow
  # the same path, making the system more predictable and maintainable.
  #
  # ## Usage
  #
  # The module is automatically included in all measurement classes:
  #
  # ```
  # weight = Unit::Weight.new(5, :pound)
  #
  # # Using convert_to
  # weight_kg = weight.convert_to(:kilogram) # => 2.27 kg
  #
  # # Using the shorter alias
  # weight_g = weight.to(:gram) # => 2267.96 g
  #
  # # No conversion needed - returns self
  # same = weight.to(:pound) # => 5 lb (same instance)
  # ```
  #
  # ## Implementation Requirements
  #
  # Classes including this module must implement:
  # - `self.conversion_factor(unit)` - Returns the factor to convert to base unit
  # - `self.new(value, unit)` - Constructor for creating new instances
  module Conversion
    # Converts this measurement to the specified target unit.
    #
    # Creates a new measurement instance with the converted value and target unit.
    # If converting to the same unit, returns self for efficiency.
    #
    # ```
    # weight = Unit::Weight.new(1000, :gram)
    # kg = weight.convert_to(:kilogram) # => Unit::Weight(1, :kilogram)
    #
    # # Converting to same unit returns self
    # same = weight.convert_to(:gram) # => returns original instance
    # ```
    #
    # @param target_unit The unit to convert to (enum value or symbol)
    # @return A new measurement with the converted value, or self if no conversion needed
    def convert_to(target_unit)
      # No conversion needed if units are the same
      return self if @unit == target_unit

      # Convert to base unit, then to target unit
      base_value = to_base_unit_value
      target_factor = self.class.conversion_factor(target_unit)
      new_value = base_value / target_factor

      # Create new instance with converted value
      self.class.new(new_value, target_unit)
    end

    # Alias for convert_to that provides a more natural API.
    #
    # This shorter method name allows for more fluent and readable code:
    #
    # ```
    # # More natural reading
    # meters = length.to(:meter)
    # pounds = weight.to(:pound)
    #
    # # Instead of
    # meters = length.convert_to(:meter)
    # ```
    #
    # @param target_unit The unit to convert to (enum value or symbol)
    # @return A new measurement with the converted value
    def to(target_unit)
      convert_to(target_unit)
    end

    # Converts the current measurement value to its base unit equivalent
    #
    # This is used internally by the conversion system to normalize
    # values before converting to the target unit.
    #
    # @return [BigDecimal] The value in base unit terms
    private def to_base_unit_value : BigDecimal
      @value * self.class.conversion_factor(@unit)
    end
  end
end
