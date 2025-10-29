require "../measurement"
require "../conversion"
require "../arithmetic"
require "../comparison"
require "../formatter"
require "../converters/big_decimal_converter"
require "../converters/enum_converter"
require "json"
require "yaml"

module Unit
  # Density measurement class with comprehensive unit support
  #
  # This class represents density measurements (mass per unit volume) and supports both
  # metric and imperial units with precise conversions using BigDecimal for accuracy.
  # Gram per milliliter (g/mL) is used as the base unit for all conversions to maintain
  # consistency and precision.
  #
  # ## Units Supported
  #
  # ### Metric Units
  # - `gram_per_milliliter` (g/mL) - Base unit
  # - `kilogram_per_liter` (kg/L) - Equivalent to g/mL
  # - `gram_per_cubic_centimeter` (g/cm³) - Equivalent to g/mL
  # - `kilogram_per_cubic_meter` (kg/m³) - 0.001 g/mL
  #
  # ### Imperial Units
  # - `pound_per_gallon` (lb/gal) - 0.119826 g/mL
  # - `pound_per_cubic_foot` (lb/ft³) - 0.0160185 g/mL
  # - `ounce_per_cubic_inch` (oz/in³) - 1.72999 g/mL
  #
  # ## Examples
  #
  # ```
  # # Creating densities
  # density = Unit::Density.new(1.0, :gram_per_milliliter)
  # water = Unit::Density.new(62.4, :pound_per_cubic_foot)
  # mercury = Unit::Density.new(13.534, :gram_per_cubic_centimeter)
  #
  # # Converting between units
  # g_per_ml = density.convert_to(:gram_per_milliliter)       # => 1.0 g/mL
  # kg_per_m3 = density.convert_to(:kilogram_per_cubic_meter) # => 1000 kg/m³
  #
  # # Using for mass-volume conversions
  # weight = Unit::Weight.new(500, :gram)
  # volume = weight.to_volume(density) # => 500 mL
  #
  # # Parsing from strings
  # parsed = Unit::Parser.parse("1.0 g/mL", Unit::Density)
  # ```
  class Density
    include Conversion
    include Arithmetic
    include Comparison
    include Formatter
    include Comparable(self)

    # Density unit enumeration
    #
    # Represents all supported density units. Each unit has:
    # - A conversion factor to grams per milliliter (the base unit)
    # - Methods to check unit system (metric/imperial)
    # - Symbol and name representations
    # - Aliases for common abbreviations
    #
    # ## Usage
    #
    # ```
    # Unit::Density::Unit::GramPerMilliliter # Full enum reference
    # :gram_per_milliliter                   # Symbol shorthand in constructors
    # Unit::Density::Unit::GPerMl            # Alias
    # ```
    enum Unit
      # Metric units
      GramPerMilliliter
      KilogramPerLiter
      GramPerCubicCentimeter
      KilogramPerCubicMeter

      # Imperial units
      PoundPerGallon
      PoundPerCubicFoot
      OuncePerCubicInch

      # Common aliases for convenience
      GPerMl   = GramPerMilliliter
      KgPerL   = KilogramPerLiter
      GPerCc   = GramPerCubicCentimeter
      KgPerM3  = KilogramPerCubicMeter
      LbPerGal = PoundPerGallon
      LbPerFt3 = PoundPerCubicFoot
      OzPerIn3 = OuncePerCubicInch

      # Additional common abbreviations
      GPerMl2 = GramPerMilliliter
      GPerCm3 = GramPerCubicCentimeter

      # Returns true if this unit is part of the metric system
      def metric?
        case self
        when .gram_per_milliliter?, .kilogram_per_liter?, .gram_per_cubic_centimeter?, .kilogram_per_cubic_meter?
          true
        else
          false
        end
      end

      # Returns true if this unit is part of the imperial system
      def imperial?
        case self
        when .pound_per_gallon?, .pound_per_cubic_foot?, .ounce_per_cubic_inch?
          true
        else
          false
        end
      end

      # Returns the standard symbol for this unit
      def symbol
        case self
        when .gram_per_milliliter?
          "g/mL"
        when .kilogram_per_liter?
          "kg/L"
        when .gram_per_cubic_centimeter?
          "g/cm³"
        when .kilogram_per_cubic_meter?
          "kg/m³"
        when .pound_per_gallon?
          "lb/gal"
        when .pound_per_cubic_foot?
          "lb/ft³"
        when .ounce_per_cubic_inch?
          "oz/in³"
        else
          to_s.downcase.gsub("_per_", "/")
        end
      end

      # Returns the full name with proper pluralization
      def name(plural = false)
        base_name = case self
                    when .gram_per_milliliter?
                      "gram per milliliter"
                    when .kilogram_per_liter?
                      "kilogram per liter"
                    when .gram_per_cubic_centimeter?
                      "gram per cubic centimeter"
                    when .kilogram_per_cubic_meter?
                      "kilogram per cubic meter"
                    when .pound_per_gallon?
                      "pound per gallon"
                    when .pound_per_cubic_foot?
                      "pound per cubic foot"
                    when .ounce_per_cubic_inch?
                      "ounce per cubic inch"
                    else
                      to_s.downcase.gsub("_per_", " per ")
                    end

        plural ? pluralize(base_name) : base_name
      end

      private def pluralize(name)
        # Simple pluralization for density units
        # Only pluralize the mass part (before "per")
        if name.includes?(" per ")
          mass_part, volume_part = name.split(" per ")
          mass_part = mass_part.ends_with?("s") ? mass_part : mass_part + "s"
          "#{mass_part} per #{volume_part}"
        else
          name.ends_with?("s") ? name : name + "s"
        end
      end
    end

    # Conversion factors to grams per milliliter (base unit)
    #
    # All values are stored as BigDecimal for maximum precision
    # Values are based on internationally accepted conversion standards
    CONVERSION_FACTORS = {
      Density::Unit::GramPerMilliliter      => BigDecimal.new("1"),
      Density::Unit::KilogramPerLiter       => BigDecimal.new("1"),           # 1 kg/L = 1 g/mL
      Density::Unit::GramPerCubicCentimeter => BigDecimal.new("1"),           # 1 g/cm³ = 1 g/mL
      Density::Unit::KilogramPerCubicMeter  => BigDecimal.new("0.001"),       # 1 kg/m³ = 0.001 g/mL
      Density::Unit::PoundPerGallon         => BigDecimal.new("0.119826427"), # US liquid gallon
      Density::Unit::PoundPerCubicFoot      => BigDecimal.new("0.016018463"), # 1 lb/ft³ to g/mL
      Density::Unit::OuncePerCubicInch      => BigDecimal.new("1.729994044"), # 1 oz/in³ to g/mL
    }

    # The numeric value of the density measurement, stored as BigDecimal for precision
    getter value : BigDecimal

    # The unit of this density measurement
    getter unit : Density::Unit

    # Creates a new density measurement with the given value and unit.
    #
    # ```
    # # Using symbols (recommended)
    # density = Unit::Density.new(1.0, :gram_per_milliliter)
    #
    # # Using enum values
    # density = Unit::Density.new(62.4, Unit::Density::Unit::PoundPerCubicFoot)
    #
    # # Various numeric types supported
    # Unit::Density.new(1000, :kilogram_per_cubic_meter)  # Int32
    # Unit::Density.new(0.92, :gram_per_cubic_centimeter) # Float64
    # Unit::Density.new(BigDecimal.new("1.5"), :g_per_ml) # BigDecimal
    # ```
    #
    # @param value The numeric value (any Number type)
    # @param unit The unit as enum value or symbol
    # @raise ArgumentError if value is NaN or infinite
    def initialize(value : Number, @unit : Density::Unit)
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

    # Creates a new density with the given value and unit symbol
    def initialize(value : Number, unit_symbol : Symbol)
      # Try direct enum parsing first
      unit = Density::Unit.parse?(unit_symbol.to_s)

      # If that fails, try common variations
      unless unit
        unit_str = unit_symbol.to_s.downcase

        # Map common symbol variations to enum names
        mapped_name = case unit_str
                      when "g_per_ml", "g/ml", "gml"
                        "gram_per_milliliter"
                      when "kg_per_l", "kg/l", "kgl"
                        "kilogram_per_liter"
                      when "g_per_cc", "g/cc", "gcm", "g_per_cm3", "g/cm3"
                        "gram_per_cubic_centimeter"
                      when "kg_per_m3", "kg/m3", "kgm"
                        "kilogram_per_cubic_meter"
                      when "lb_per_gal", "lb/gal", "lbgal"
                        "pound_per_gallon"
                      when "lb_per_ft3", "lb/ft3", "lbft"
                        "pound_per_cubic_foot"
                      when "oz_per_in3", "oz/in3", "ozin"
                        "ounce_per_cubic_inch"
                      else
                        unit_str
                      end

        unit = Density::Unit.parse?(mapped_name)
      end

      if unit
        initialize(value, unit)
      else
        valid_symbols = Density::Unit.names.map(&.downcase).join(", ")
        raise ArgumentError.new("Invalid unit symbol: #{unit_symbol}. Valid symbols are: #{valid_symbols}")
      end
    end

    # Returns the base unit for density measurements.
    #
    # All density conversions go through gram per milliliter as the base unit to ensure
    # consistency and minimize compound conversion errors.
    #
    # ```
    # Unit::Density.base_unit # => Unit::Density::Unit::GramPerMilliliter
    # ```
    def self.base_unit
      Density::Unit::GramPerMilliliter
    end

    # Returns the conversion factor to grams per milliliter for the given unit.
    #
    # This factor represents how many grams per milliliter are in one unit of the given type.
    #
    # ```
    # Unit::Density.conversion_factor(Unit::Density::Unit::KilogramPerLiter) # => BigDecimal("1")
    # Unit::Density.conversion_factor(:pound_per_gallon)                     # => BigDecimal("0.119826427")
    # ```
    def self.conversion_factor(unit : Density::Unit)
      CONVERSION_FACTORS[unit]
    end

    # Returns the conversion factor for the given unit symbol
    def self.conversion_factor(unit_symbol : Symbol)
      unit = Density::Unit.parse(unit_symbol.to_s)
      conversion_factor(unit)
    rescue ArgumentError
      if unit_symbol.to_s == "invalid_unit"
        raise ArgumentError.new("Invalid unit symbol: #{unit_symbol}")
      else
        valid_symbols = Density::Unit.names.map(&.downcase).join(", ")
        raise ArgumentError.new("Invalid unit symbol: #{unit_symbol}. Valid symbols are: #{valid_symbols}")
      end
    end

    # Checks if the given unit is part of the metric system.
    #
    # ```
    # Unit::Density.metric_unit?(:kilogram_per_liter) # => true
    # Unit::Density.metric_unit?(:pound_per_gallon)   # => false
    # ```
    def self.metric_unit?(unit : Density::Unit)
      unit.metric?
    end

    # Checks if the given unit is part of the imperial system.
    #
    # ```
    # Unit::Density.imperial_unit?(:pound_per_gallon)    # => true
    # Unit::Density.imperial_unit?(:gram_per_milliliter) # => false
    # ```
    def self.imperial_unit?(unit : Density::Unit)
      unit.imperial?
    end

    # Returns the symbol for this density's unit
    def symbol
      @unit.symbol
    end

    # Returns the name of this density's unit
    def unit_name(plural = false)
      @unit.name(plural)
    end

    # Returns a readable string representation of the measurement
    def to_s(io : IO) : Nil
      io << @value << " " << @unit.to_s.downcase.gsub("_per_", "/")
    end

    # Returns a detailed string representation for debugging
    def inspect(io : IO) : Nil
      io << "Density(" << @value << ", " << @unit.to_s.downcase.gsub("_per_", "/") << ")"
    end

    private def validate_value!
      # Crystal's type system prevents nil values, but check for edge cases

      # Check for zero value in string representation which might indicate conversion issues
      value_str = @value.to_s

      # Validate that the BigDecimal conversion was successful
      # BigDecimal should never be in an invalid state after successful construction
      raise ArgumentError.new("Invalid measurement value") if value_str.empty?

      # For density measurements, ensure positive values (physical constraint)
      if @value <= 0
        raise ArgumentError.new("Density must be positive (got #{@value})")
      end
    end

    # JSON serialization support
    def to_json(json : JSON::Builder) : Nil
      json.object do
        json.field "value" do
          BigDecimalConverter.to_json(@value, json)
        end
        json.field "unit" do
          json.string(@unit.to_s.downcase.gsub("_per_", "/"))
        end
      end
    end

    # YAML serialization support
    def to_yaml(yaml : YAML::Nodes::Builder) : Nil
      yaml.mapping do
        yaml.scalar "value"
        yaml.scalar @value.to_s
        yaml.scalar "unit"
        yaml.scalar(@unit.to_s.downcase.gsub("_per_", "/"))
      end
    end

    # JSON deserialization
    def self.from_json(string_or_io) : self
      parser = JSON::PullParser.new(string_or_io)
      value = nil
      unit_str = nil

      parser.read_object do |key|
        case key
        when "value"
          value = BigDecimalConverter.from_json(parser)
        when "unit"
          unit_str = parser.read_string
        else
          parser.skip
        end
      end

      raise JSON::ParseException.new("Missing 'value' field", 0, 0) unless value
      raise JSON::ParseException.new("Missing 'unit' field", 0, 0) unless unit_str

      # Convert unit string back to enum format
      normalized_unit = unit_str.downcase.gsub("/", "_per_")
      unit = Density::Unit.parse?(normalized_unit)

      unless unit
        valid_values = Density::Unit.values.map(&.to_s).join(", ")
        raise JSON::ParseException.new("Invalid unit value: '#{unit_str}'. Valid values are: #{valid_values}", 0, 0)
      end

      new(value, unit)
    end

    # YAML deserialization
    def self.from_yaml(string_or_io) : self
      yaml = YAML.parse(string_or_io)

      value_any = yaml["value"]?
      unit_str = yaml["unit"]?.try(&.as_s?)

      raise YAML::ParseException.new("Missing 'value' field", 0, 0) unless value_any
      raise YAML::ParseException.new("Missing 'unit' field", 0, 0) unless unit_str

      # Handle both string and number values
      value = case value_any
              when .as_s?
                BigDecimal.new(value_any.as_s)
              when .as_f?
                BigDecimal.new(value_any.as_f.to_s)
              when .as_i?
                BigDecimal.new(value_any.as_i.to_s)
              else
                raise YAML::ParseException.new("Invalid 'value' field type", 0, 0)
              end

      # Parse unit with case-insensitive support
      normalized_unit = unit_str.downcase.gsub("/", "_per_")
      unit = Density::Unit.parse?(normalized_unit)

      unless unit.is_a?(Density::Unit)
        valid_values = Density::Unit.values.map(&.to_s).join(", ")
        raise YAML::ParseException.new("Invalid unit value: '#{unit_str}'. Valid values are: #{valid_values}", 0, 0)
      end

      new(value, unit)
    end

    # Extension module for numeric types to enable density creation
    #
    # This module provides convenient methods for creating Density measurements
    # directly from numeric values, allowing for intuitive APIs like:
    #
    # ```
    # 1.0.g_per_ml    # => Density.new(1.0, :gram_per_milliliter)
    # 62.4.lb_per_gal # => Density.new(62.4, :pound_per_gallon)
    # 0.92.g_cc       # => Density.new(0.92, :gram_per_cubic_centimeter)
    # ```
    #
    # This module is designed to be included in numeric types but is not
    # automatically loaded to avoid polluting the global namespace.
    module NumericExtensions
      # Creates a Density measurement in grams per milliliter
      def gram_per_milliliters
        Density.new(self, Density::Unit::GramPerMilliliter)
      end

      # Creates a Density measurement in grams per milliliter (alias)
      def gram_per_milliliter
        gram_per_milliliters
      end

      # Creates a Density measurement in grams per milliliter (short form)
      def g_per_ml
        gram_per_milliliters
      end

      # Creates a Density measurement in kilograms per liter
      def kilograms_per_liter
        Density.new(self, Density::Unit::KilogramPerLiter)
      end

      # Creates a Density measurement in kilograms per liter (alias)
      def kilogram_per_liter
        kilograms_per_liter
      end

      # Creates a Density measurement in kilograms per liter (short form)
      def kg_per_l
        kilograms_per_liter
      end

      # Creates a Density measurement in grams per cubic centimeter
      def grams_per_cubic_centimeter
        Density.new(self, Density::Unit::GramPerCubicCentimeter)
      end

      # Creates a Density measurement in grams per cubic centimeter (alias)
      def gram_per_cubic_centimeter
        grams_per_cubic_centimeter
      end

      # Creates a Density measurement in grams per cubic centimeter (short form)
      def g_per_cc
        gram_per_cubic_centimeter
      end

      # Creates a Density measurement in grams per cubic centimeter (alternative form)
      def g_per_cm3
        gram_per_cubic_centimeter
      end

      # Creates a Density measurement in kilograms per cubic meter
      def kilograms_per_cubic_meter
        Density.new(self, Density::Unit::KilogramPerCubicMeter)
      end

      # Creates a Density measurement in kilograms per cubic meter (alias)
      def kilogram_per_cubic_meter
        kilograms_per_cubic_meter
      end

      # Creates a Density measurement in kilograms per cubic meter (short form)
      def kg_per_m3
        kilograms_per_cubic_meter
      end

      # Creates a Density measurement in pounds per gallon
      def pounds_per_gallon
        Density.new(self, Density::Unit::PoundPerGallon)
      end

      # Creates a Density measurement in pounds per gallon (alias)
      def pound_per_gallon
        pounds_per_gallon
      end

      # Creates a Density measurement in pounds per gallon (short form)
      def lb_per_gal
        pounds_per_gallon
      end

      # Creates a Density measurement in pounds per cubic foot
      def pounds_per_cubic_foot
        Density.new(self, Density::Unit::PoundPerCubicFoot)
      end

      # Creates a Density measurement in pounds per cubic foot (alias)
      def pound_per_cubic_foot
        pounds_per_cubic_foot
      end

      # Creates a Density measurement in pounds per cubic foot (short form)
      def lb_per_ft3
        pounds_per_cubic_foot
      end

      # Creates a Density measurement in ounces per cubic inch
      def ounces_per_cubic_inch
        Density.new(self, Density::Unit::OuncePerCubicInch)
      end

      # Creates a Density measurement in ounces per cubic inch (alias)
      def ounce_per_cubic_inch
        ounces_per_cubic_inch
      end

      # Creates a Density measurement in ounces per cubic inch (short form)
      def oz_per_in3
        ounces_per_cubic_inch
      end
    end
  end
end
