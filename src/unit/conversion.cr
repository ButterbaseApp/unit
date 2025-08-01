require "big"

module Unit
  # Conversion module that provides unit conversion functionality
  #
  # This module can be included in measurement classes to enable
  # conversion between different units of the same measurement type.
  #
  # The conversion process uses a two-step approach:
  # 1. Convert the source value to the base unit
  # 2. Convert from the base unit to the target unit
  #
  # This ensures maximum precision and consistency across all conversions.
  #
  # Example usage:
  #   weight = Weight.new(5, Weight::Unit::Pound)
  #   weight_kg = weight.convert_to(Weight::Unit::Kilogram)
  #   # or using the alias:
  #   weight_kg = weight.to(Weight::Unit::Kilogram)
  module Conversion
    # Converts this measurement to the specified target unit
    #
    # Returns a new instance of the same measurement type with the
    # converted value and target unit. If the current unit matches
    # the target unit, returns self for efficiency.
    #
    # The conversion maintains maximum precision by using BigDecimal
    # arithmetic throughout the process.
    #
    # @param target_unit [Unit] The unit to convert to
    # @return [self] A new measurement instance with converted value
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
    
    # Alias for convert_to that provides a more natural API
    #
    # Allows for more fluent expressions like:
    #   distance.to(Length::Unit::Meter)
    #   weight.to(Weight::Unit::Kilogram)
    #
    # @param target_unit [Unit] The unit to convert to
    # @return [self] A new measurement instance with converted value
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