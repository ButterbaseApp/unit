require "big"

module Unit
  # String parsing module for converting human-readable strings into measurement objects
  #
  # Supports parsing strings like:
  #   "10.5 kg" -> Weight.new(10.5, Weight::Unit::Kilogram)
  #   "1/2 pound" -> Weight.new(0.5, Weight::Unit::Pound)
  #   "-3.14 meters" -> Length.new(-3.14, Length::Unit::Meter)
  #
  # The parser handles both decimal and fractional notation with flexible whitespace.
  module Parser
    # Regex pattern for matching fraction notation (e.g., "1/2", "3/4", "10/3")
    #
    # Captures:
    #   - Numerator (integer)
    #   - Denominator (integer, must be non-zero)
    #
    # Examples:
    #   "1/2" -> numerator: "1", denominator: "2"
    #   "10/3" -> numerator: "10", denominator: "3"
    FRACTION_REGEX = /^(-?\d+)\/(\d+)$/
    
    # Regex pattern for matching decimal numbers including negative values
    #
    # Supports:
    #   - Integers: "10", "-5"
    #   - Decimals: "10.5", "-3.14", "0.001"
    #   - Leading zeros: "0.5", "00.123"
    #
    # Examples:
    #   "10" -> "10"
    #   "-5.5" -> "-5.5"
    #   "0.001" -> "0.001"
    DECIMAL_REGEX = /^-?\d+(?:\.\d+)?$/
    
    # Regex pattern for matching complete measurement strings
    #
    # Captures:
    #   - Value (decimal or fraction)
    #   - Unit string (letters, case-insensitive)
    #
    # Supports flexible whitespace between value and unit, including:
    # - No space between value and unit: "10kg"
    # - Multiple spaces: "10   kg"
    # - Tab characters: "10\tkg"
    # - Leading/trailing whitespace: " 10 kg "
    #
    # Examples:
    #   "10 kg" -> value: "10", unit: "kg"
    #   "1/2 pound" -> value: "1/2", unit: "pound"
    #   "-3.14 meters" -> value: "-3.14", unit: "meters"
    #   "5.5kg" -> value: "5.5", unit: "kg" (no space)
    #   "  10   kg  " -> value: "10", unit: "kg" (extra whitespace)
    MEASUREMENT_REGEX = /^\s*(-?\d+(?:\/\d+|\.\d+)?)\s*([a-zA-Z]+)\s*$/
    
    # Parses a value string into either BigDecimal or BigRational
    #
    # First checks if the value matches the fraction pattern (e.g., "1/2").
    # If so, creates a BigRational from numerator and denominator.
    # Otherwise, parses as a BigDecimal for decimal values.
    #
    # Args:
    #   value_str: String containing the numeric value to parse
    #
    # Returns:
    #   BigRational for fractions, BigDecimal for decimal values
    #
    # Raises:
    #   ArgumentError: If the value cannot be parsed or denominator is zero
    #
    # Examples:
    #   parse_value("1/2") -> BigRational.new(1, 2)
    #   parse_value("10.5") -> BigDecimal.new("10.5")
    #   parse_value("-3.14") -> BigDecimal.new("-3.14")
    def self.parse_value(value_str : String) : BigDecimal | BigRational
      # First try to parse as fraction
      if fraction_match = FRACTION_REGEX.match(value_str.strip)
        numerator = fraction_match[1].to_i
        denominator = fraction_match[2].to_i
        
        if denominator == 0
          raise ArgumentError.new("Division by zero in fraction: #{value_str}")
        end
        
        return BigRational.new(numerator, denominator)
      end
      
      # Then try to parse as decimal
      if DECIMAL_REGEX.match(value_str.strip)
        return BigDecimal.new(value_str.strip)
      end
      
      # If neither pattern matches, raise an error
      raise ArgumentError.new("Invalid numeric value: #{value_str}")
    end
    
    # Parses a unit string for Weight measurements
    def self.parse_unit(weight_class : Weight.class, unit_str : String) : Weight::Unit
      unit_str_lower = unit_str.strip.downcase
      
      Weight::Unit.each do |unit|
        # Strategy 1: Match enum string representation
        return unit if unit.to_s.downcase == unit_str_lower
        
        # Strategy 2: Match unit symbol
        begin
          return unit if unit.symbol.downcase == unit_str_lower
        rescue
          # Continue if symbol method fails
        end
        
        # Strategy 3: Match unit name (singular and plural)
        begin
          return unit if unit.name.downcase == unit_str_lower
          return unit if unit.name(plural: true).downcase == unit_str_lower
        rescue
          # Continue if name method fails
        end
      end
      
      raise ArgumentError.new("Unknown unit: #{unit_str}")
    end
    
    # Parses a unit string for Length measurements
    def self.parse_unit(length_class : Length.class, unit_str : String) : Length::Unit
      unit_str_lower = unit_str.strip.downcase
      
      Length::Unit.each do |unit|
        # Strategy 1: Match enum string representation
        return unit if unit.to_s.downcase == unit_str_lower
        
        # Strategy 2: Match unit symbol
        begin
          return unit if unit.symbol.downcase == unit_str_lower
        rescue
          # Continue if symbol method fails
        end
        
        # Strategy 3: Match unit name (singular and plural)
        begin
          return unit if unit.name.downcase == unit_str_lower
          return unit if unit.name(plural: true).downcase == unit_str_lower
        rescue
          # Continue if name method fails
        end
      end
      
      raise ArgumentError.new("Unknown unit: #{unit_str}")
    end
    
    # Parses a measurement string into a Weight object
    #
    # Examples:
    #   parse(Weight, "10.5 kg") -> Weight.new(10.5, Weight::Unit::Kilogram)
    #   parse(Weight, "1/2 pound") -> Weight.new(0.5, Weight::Unit::Pound)
    #   parse(Weight, "-3 g") -> Weight.new(-3, Weight::Unit::Gram)
    def self.parse(weight_class : Weight.class, input : String) : Weight
      match = MEASUREMENT_REGEX.match(input.strip)
      raise ArgumentError.new("Invalid format: #{input}") unless match
      
      value_str = match[1]
      unit_str = match[2]
      
      # Parse value (decimal or fraction)
      value = parse_value(value_str)
      
      # Parse unit
      unit = parse_unit(Weight, unit_str)
      
      Weight.new(value, unit)
    end
    
    # Parses a measurement string into a Length object
    #
    # Examples:
    #   parse(Length, "10.5 m") -> Length.new(10.5, Length::Unit::Meter)
    #   parse(Length, "1/2 foot") -> Length.new(0.5, Length::Unit::Foot)
    #   parse(Length, "-3 cm") -> Length.new(-3, Length::Unit::Centimeter)
    def self.parse(length_class : Length.class, input : String) : Length
      match = MEASUREMENT_REGEX.match(input.strip)
      raise ArgumentError.new("Invalid format: #{input}") unless match
      
      value_str = match[1]
      unit_str = match[2]
      
      # Parse value (decimal or fraction)
      value = parse_value(value_str)
      
      # Parse unit
      unit = parse_unit(Length, unit_str)
      
      Length.new(value, unit)
    end
  end
end