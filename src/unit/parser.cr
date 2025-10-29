require "big"

module Unit
  # Parser for converting human-readable strings into measurement objects
  #
  # The Parser module provides a flexible string parsing system that can handle
  # various formats of measurement input, including decimal numbers, fractions,
  # and different unit representations.
  #
  # ## Supported Formats
  #
  # ### Numeric Values
  # - Decimal: `"10.5"`, `"0.001"`, `"-3.14"`
  # - Fractions: `"1/2"`, `"3/4"`, `"10/3"`
  # - Negative values: `"-5"`, `"-1/2"`
  #
  # ### Unit Matching
  # - Full names: `"kilogram"`, `"pound"`, `"meter"`
  # - Plurals: `"kilograms"`, `"pounds"`, `"meters"`
  # - Symbols: `"kg"`, `"lb"`, `"m"`
  # - Case insensitive: `"KG"`, `"Kilogram"`, `"POUND"`
  #
  # ### Whitespace Handling
  # - No space: `"10kg"`
  # - Single space: `"10 kg"`
  # - Multiple spaces: `"10   kg"`
  # - Leading/trailing: `"  10 kg  "`
  #
  # ## Examples
  #
  # ```
  # # Basic decimal parsing
  # weight = Unit::Parser.parse("10.5 kg", Unit::Weight)
  # length = Unit::Parser.parse("2.5 meters", Unit::Length)
  #
  # # Fraction parsing
  # half_pound = Unit::Parser.parse("1/2 pound", Unit::Weight)
  # quarter_cup = Unit::Parser.parse("1/4 cup", Unit::Volume)
  #
  # # Various formats
  # Unit::Parser.parse("10kg", Unit::Weight)         # No space
  # Unit::Parser.parse("10 KG", Unit::Weight)        # Uppercase
  # Unit::Parser.parse("10 kilograms", Unit::Weight) # Plural
  #
  # # Error handling
  # Unit::Parser.parse("invalid", Unit::Weight) # Raises ArgumentError
  # ```
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
    #   - Unit string (letters, letters with slashes, or symbols, case-insensitive)
    #
    # Supports flexible whitespace between value and unit, including:
    # - No space between value and unit: "10kg"
    # - Multiple spaces: "10   kg"
    # - Tab characters: "10\tkg"
    # - Leading/trailing whitespace: " 10 kg "
    # - Density units with slashes: "1.0 g/mL", "62.4 lb/ft³"
    #
    # Examples:
    #   "10 kg" -> value: "10", unit: "kg"
    #   "1/2 pound" -> value: "1/2", unit: "pound"
    #   "-3.14 meters" -> value: "-3.14", unit: "meters"
    #   "5.5kg" -> value: "5.5", unit: "kg" (no space)
    #   "  10   kg  " -> value: "10", unit: "kg" (extra whitespace)
    #   "1.0 g/mL" -> value: "1.0", unit: "g/mL" (density)
    #   "62.4 lb/ft³" -> value: "62.4", unit: "lb/ft³" (density)
    MEASUREMENT_REGEX = /^\s*(-?\d+(?:\/\d+|\.\d+)?)\s*([a-zA-Z\/³]+)\s*$/

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

    # Parses a measurement string into a Weight object.
    #
    # Accepts various string formats and returns a properly typed Weight measurement.
    # The parser is flexible with whitespace and case-insensitive for units.
    #
    # ```
    # # Decimal values
    # Unit::Parser.parse("10.5 kg", Unit::Weight) # => Weight(10.5, :kilogram)
    # Unit::Parser.parse("2.25 lb", Unit::Weight) # => Weight(2.25, :pound)
    #
    # # Fractions
    # Unit::Parser.parse("1/2 pound", Unit::Weight) # => Weight(0.5, :pound)
    # Unit::Parser.parse("3/4 oz", Unit::Weight)    # => Weight(0.75, :ounce)
    #
    # # Negative values
    # Unit::Parser.parse("-3 g", Unit::Weight) # => Weight(-3, :gram)
    #
    # # Flexible spacing
    # Unit::Parser.parse("10kg", Unit::Weight)    # No space
    # Unit::Parser.parse("10   kg", Unit::Weight) # Multiple spaces
    # ```
    #
    # @param weight_class The Weight class (for type inference)
    # @param input The string to parse
    # @return A new Weight instance
    # @raise ArgumentError if the format is invalid or unit is unknown
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

    # Parses a unit string for Volume measurements
    def self.parse_unit(volume_class : Volume.class, unit_str : String) : Volume::Unit
      unit_str_lower = unit_str.strip.downcase

      Volume::Unit.each do |unit|
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

    # Parses a measurement string into a Volume object
    #
    # Examples:
    #   parse(Volume, "2.5 L") -> Volume.new(2.5, Volume::Unit::Liter)
    #   parse(Volume, "1/2 cup") -> Volume.new(0.5, Volume::Unit::Cup)
    #   parse(Volume, "500 ml") -> Volume.new(500, Volume::Unit::Milliliter)
    def self.parse(volume_class : Volume.class, input : String) : Volume
      match = MEASUREMENT_REGEX.match(input.strip)
      raise ArgumentError.new("Invalid format: #{input}") unless match

      value_str = match[1]
      unit_str = match[2]

      # Parse value (decimal or fraction)
      value = parse_value(value_str)

      # Parse unit
      unit = parse_unit(Volume, unit_str)

      Volume.new(value, unit)
    end

    # Parses a unit string for Density measurements
    def self.parse_unit(density_class : Density.class, unit_str : String) : Density::Unit
      unit_str_lower = unit_str.strip.downcase

      # Replace common abbreviations first
      normalized = unit_str_lower
        .gsub("ml", "milliliter")
        .gsub("l", "liter")
        .gsub("kg", "kilogram")
        .gsub("cc", "cubic_centimeter")
        .gsub("cm3", "cubic_centimeter")
        .gsub("m3", "cubic_meter")
        .gsub("gal", "gallon")
        .gsub("ft3", "cubic_foot")
        .gsub("in3", "cubic_inch")

      # Handle the "g" abbreviation carefully to avoid replacing "gram"
      if unit_str_lower.includes?("g/") || unit_str_lower.includes?("/g")
        normalized = normalized.gsub("g", "gram")
      else
        normalized = normalized.gsub(/^g$/, "gram").gsub(/g$/, "gram")
      end

      # Replace "/" with "_per_" for compound units
      if normalized.includes?("/")
        normalized = normalized.gsub("/", "_per_")
      end

      Density::Unit.each do |unit|
        # Strategy 1: Match enum string representation
        return unit if unit.to_s.downcase == normalized

        # Strategy 2: Match unit symbol
        begin
          return unit if unit.symbol.downcase == unit_str_lower
        rescue
          # Continue if symbol method fails
        end

        # Strategy 3: Match unit name (singular and plural)
        begin
          return unit if unit.name.downcase == normalized
          return unit if unit.name(plural: true).downcase == normalized
        rescue
          # Continue if name method fails
        end
      end

      raise ArgumentError.new("Unknown unit: #{unit_str}")
    end

    # Parses a measurement string into a Density object
    #
    # Examples:
    #   parse(Density, "1.0 g/mL") -> Density.new(1.0, Density::Unit::GramPerMilliliter)
    #   parse(Density, "62.4 lb/ft³") -> Density.new(62.4, Density::Unit::PoundPerCubicFoot)
    #   parse(Density, "0.92 g/cc") -> Density.new(0.92, Density::Unit::GramPerCubicCentimeter)
    def self.parse(density_class : Density.class, input : String) : Density
      match = MEASUREMENT_REGEX.match(input.strip)
      raise ArgumentError.new("Invalid format: #{input}") unless match

      value_str = match[1]
      unit_str = match[2]

      # Parse value (decimal or fraction)
      value = parse_value(value_str)

      # Parse unit
      unit = parse_unit(Density, unit_str)

      Density.new(value, unit)
    end
  end
end
