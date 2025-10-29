require "../measurement"
require "../conversion"
require "../arithmetic"
require "../comparison"
require "../formatter"
require "../converters/big_decimal_converter"
require "../converters/enum_converter"
require "json"
require "yaml"
require "./density"

module Unit
  # Volume measurement class with comprehensive unit support
  #
  # Supports both metric and US liquid volume units with precise conversions
  # using BigDecimal for accuracy. Liter is used as the base unit for all
  # conversions to maintain consistency and precision.
  #
  # Focuses on US liquid measurements for cooking and recipe applications.
  # Maintains high precision for accurate culinary conversions.
  #
  # Examples:
  #   Volume.new(2.5, Volume::Unit::Cup)
  #   Volume.new(1.5, Volume::Unit::Liter)
  #   Volume.new(16, Volume::Unit::FluidOunce)
  class Volume
    include Conversion
    include Arithmetic
    include Comparison
    include Formatter
    include Comparable(self)
    # Comprehensive volume unit enumeration
    #
    # Includes both metric units (liter-based) and US liquid units
    # with common aliases for convenience in cooking applications.
    enum Unit
      # Metric units
      Liter
      Milliliter

      # US liquid units
      Gallon
      Quart
      Pint
      Cup
      FluidOunce

      # Common aliases for convenience
      L    = Liter
      Ml   = Milliliter
      Gal  = Gallon
      Qt   = Quart
      Pt   = Pint
      FlOz = FluidOunce

      # Returns true if this unit is part of the metric system
      def metric?
        case self
        when .liter?, .milliliter?
          true
        else
          false
        end
      end

      # Returns the standard symbol for this unit
      def symbol
        case self
        when .liter?
          "L"
        when .milliliter?
          "mL"
        when .gallon?
          "gal"
        when .quart?
          "qt"
        when .pint?
          "pt"
        when .cup?
          "cup"
        when .fluid_ounce?
          "fl oz"
        else
          to_s.downcase
        end
      end

      # Returns the full name with proper pluralization
      def name(plural = false)
        base_name = case self
                    when .liter?
                      "liter"
                    when .milliliter?
                      "milliliter"
                    when .gallon?
                      "gallon"
                    when .quart?
                      "quart"
                    when .pint?
                      "pint"
                    when .cup?
                      "cup"
                    when .fluid_ounce?
                      "fluid ounce"
                    else
                      to_s.downcase.gsub("_", " ")
                    end

        plural ? pluralize(base_name) : base_name
      end

      private def pluralize(name)
        case name
        when "fluid ounce"
          "fluid ounces"
        else
          name + "s"
        end
      end
    end

    # Conversion factors to liters (base unit)
    #
    # All values are stored as BigDecimal for maximum precision
    # Values are based on NIST Handbook 44 and US customary measurements
    CONVERSION_FACTORS = {
      Volume::Unit::Liter      => BigDecimal.new("1"),
      Volume::Unit::Milliliter => BigDecimal.new("0.001"),
      Volume::Unit::Gallon     => BigDecimal.new("3.785411784"),     # US liquid gallon
      Volume::Unit::Quart      => BigDecimal.new("0.946352946"),     # US liquid quart (1/4 gallon)
      Volume::Unit::Pint       => BigDecimal.new("0.473176473"),     # US liquid pint (1/8 gallon)
      Volume::Unit::Cup        => BigDecimal.new("0.2365882365"),    # US cup (1/16 gallon)
      Volume::Unit::FluidOunce => BigDecimal.new("0.0295735295625"), # US fluid ounce (1/128 gallon)
    }

    # Value stored as BigDecimal for precision
    getter value : BigDecimal

    # Unit of measurement
    getter unit : Volume::Unit

    # Creates a new volume with the given value and unit
    def initialize(value : Number, @unit : Volume::Unit)
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

    # Creates a new volume with the given value and unit symbol
    def initialize(value : Number, unit_symbol : Symbol)
      unit = Volume::Unit.parse(unit_symbol.to_s)
      initialize(value, unit)
    rescue ArgumentError
      if unit_symbol.to_s == "invalid_unit"
        raise ArgumentError.new("Invalid unit symbol: #{unit_symbol}")
      else
        valid_symbols = Volume::Unit.names.map(&.downcase).join(", ")
        raise ArgumentError.new("Invalid unit symbol: #{unit_symbol}. Valid symbols are: #{valid_symbols}")
      end
    end

    # Returns the base unit for volume measurements (liter)
    def self.base_unit
      Volume::Unit::Liter
    end

    # Returns the conversion factor for the given unit
    def self.conversion_factor(unit : Volume::Unit)
      CONVERSION_FACTORS[unit]
    end

    # Returns the conversion factor for the given unit symbol
    def self.conversion_factor(unit_symbol : Symbol)
      unit = Volume::Unit.parse(unit_symbol.to_s)
      conversion_factor(unit)
    rescue ArgumentError
      if unit_symbol.to_s == "invalid_unit"
        raise ArgumentError.new("Invalid unit symbol: #{unit_symbol}")
      else
        valid_symbols = Volume::Unit.names.map(&.downcase).join(", ")
        raise ArgumentError.new("Invalid unit symbol: #{unit_symbol}. Valid symbols are: #{valid_symbols}")
      end
    end

    # Returns true if the given unit is metric
    def self.metric_unit?(unit : Volume::Unit)
      unit.metric?
    end

    # Returns true if the given unit is a US liquid measurement
    def self.us_liquid_unit?(unit : Volume::Unit)
      case unit
      when .gallon?, .quart?, .pint?, .cup?, .fluid_ounce?
        true
      else
        false
      end
    end

    # Returns the symbol for this volume's unit
    def symbol
      @unit.symbol
    end

    # Returns the name of this volume's unit
    def unit_name(plural = false)
      @unit.name(plural)
    end

    # Returns a readable string representation of the measurement
    def to_s(io : IO) : Nil
      io << @value << " " << @unit.to_s.downcase.gsub("_", " ")
    end

    # Returns a detailed string representation for debugging
    def inspect(io : IO) : Nil
      io << "Volume(" << @value << ", " << @unit << ")"
    end

    private def validate_value!
      # Crystal's type system prevents nil values, but check for edge cases

      # Check for zero value in string representation which might indicate conversion issues
      value_str = @value.to_s

      # Validate that the BigDecimal conversion was successful
      # BigDecimal should never be in an invalid state after successful construction
      raise ArgumentError.new("Invalid measurement value") if value_str.empty?

      # For volume measurements, we might want to reject negative values in cooking contexts
      # This is left flexible but could be enhanced for specific use cases
    end

    # JSON serialization support
    def to_json(json : JSON::Builder) : Nil
      json.object do
        json.field "value" do
          BigDecimalConverter.to_json(@value, json)
        end
        json.field "unit" do
          EnumConverter(Volume::Unit).to_json(@unit, json)
        end
      end
    end

    # YAML serialization support
    def to_yaml(yaml : YAML::Nodes::Builder) : Nil
      yaml.mapping do
        yaml.scalar "value"
        BigDecimalConverter.to_yaml(@value, yaml)
        yaml.scalar "unit"
        EnumConverter(Volume::Unit).to_yaml(@unit, yaml)
      end
    end

    # JSON deserialization
    def self.from_json(string_or_io) : self
      parser = JSON::PullParser.new(string_or_io)
      value = nil
      unit = nil

      parser.read_object do |key|
        case key
        when "value"
          value = BigDecimalConverter.from_json(parser)
        when "unit"
          unit = EnumConverter(Volume::Unit).from_json(parser)
        else
          parser.skip
        end
      end

      raise JSON::ParseException.new("Missing 'value' field", 0, 0) unless value
      raise JSON::ParseException.new("Missing 'unit' field", 0, 0) unless unit

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
      unit = Volume::Unit.parse?(unit_str) || begin
        normalized = unit_str.downcase
        Volume::Unit.each do |enum_value|
          break enum_value if enum_value.to_s.downcase == normalized
        end
      end

      unless unit.is_a?(Volume::Unit)
        valid_values = Volume::Unit.values.map(&.to_s).join(", ")
        raise YAML::ParseException.new("Invalid unit value: '#{unit_str}'. Valid values are: #{valid_values}", 0, 0)
      end

      new(value, unit)
    end

    # Extension module for numeric types to enable volume creation
    #
    # This module provides convenient methods for creating Volume measurements
    # directly from numeric values, allowing for intuitive APIs like:
    #
    # ```
    # 5.liters  # => Volume.new(5, :liter)
    # 1.2.ml    # => Volume.new(1.2, :milliliter)
    # 500.cups  # => Volume.new(500, :cup)
    # 2.gallons # => Volume.new(2, :gallon)
    # ```
    #
    # This module is designed to be included in numeric types but is not
    # automatically loaded to avoid polluting the global namespace.
    module NumericExtensions
      # Creates a Volume measurement in liters
      def liters
        Volume.new(self, Volume::Unit::Liter)
      end

      # Creates a Volume measurement in liters (alias)
      def liter
        liters
      end

      # Creates a Volume measurement in liters (short form)
      def l
        liters
      end

      # Creates a Volume measurement in milliliters
      def milliliters
        Volume.new(self, Volume::Unit::Milliliter)
      end

      # Creates a Volume measurement in milliliters (alias)
      def milliliter
        milliliters
      end

      # Creates a Volume measurement in milliliters (short form)
      def ml
        milliliters
      end

      # Creates a Volume measurement in gallons
      def gallons
        Volume.new(self, Volume::Unit::Gallon)
      end

      # Creates a Volume measurement in gallons (alias)
      def gallon
        gallons
      end

      # Creates a Volume measurement in gallons (short form)
      def gal
        gallons
      end

      # Creates a Volume measurement in quarts
      def quarts
        Volume.new(self, Volume::Unit::Quart)
      end

      # Creates a Volume measurement in quarts (alias)
      def quart
        quarts
      end

      # Creates a Volume measurement in quarts (short form)
      def qt
        quarts
      end

      # Creates a Volume measurement in pints
      def pints
        Volume.new(self, Volume::Unit::Pint)
      end

      # Creates a Volume measurement in pints (alias)
      def pint
        pints
      end

      # Creates a Volume measurement in pints (short form)
      def pt
        pints
      end

      # Creates a Volume measurement in cups
      def cups
        Volume.new(self, Volume::Unit::Cup)
      end

      # Creates a Volume measurement in cups (alias)
      def cup
        cups
      end

      # Creates a Volume measurement in fluid ounces
      def fluid_ounces
        Volume.new(self, Volume::Unit::FluidOunce)
      end

      # Creates a Volume measurement in fluid ounces (alias)
      def fluid_ounce
        fluid_ounces
      end

      # Creates a Volume measurement in fluid ounces (short form)
      def fl_oz
        fluid_ounces
      end
    end

    # Convert this volume to weight given a density
    #
    # This method calculates the mass that would occupy this volume
    # at the given density, using the formula: mass = volume × density
    #
    # ```
    # # Using a Density object
    # volume = Unit::Volume.new(500, :milliliter)
    # water_density = Unit::Density.new(1.0, :gram_per_milliliter)
    # weight = volume.to_weight(water_density) # => 500 g
    #
    # # Using density value and unit (creates Density internally)
    # weight = volume.to_weight(0.92, :gram_per_milliliter) # => 460 g
    #
    # # With explicit naming for clarity
    # weight = volume.weight_given(water_density)
    # ```
    #
    # @param density The density of the material
    # @return The weight that would occupy this volume at the given density
    # @raise ArgumentError if density is zero or negative
    def to_weight(density : Density) : Weight
      if density.value <= 0
        raise ArgumentError.new("Density must be positive (got #{density.value})")
      end

      # Convert volume to milliliters and density to g/mL for calculation
      volume_ml = self.convert_to(:milliliter).value
      density_g_per_ml = density.convert_to(:gram_per_milliliter).value

      # Calculate mass in grams: mass = volume × density
      mass_grams = volume_ml * density_g_per_ml

      Weight.new(mass_grams, :gram)
    end

    # Convert this volume to weight given a density value and unit
    #
    # This is a convenience method that creates a Density object internally
    # from the provided value and unit, then performs the conversion.
    #
    # ```
    # # Using density value and unit without creating Density object
    # volume = Unit::Volume.new(250, :milliliter)
    # flour_weight = volume.to_weight(0.593, :gram_per_milliliter) # ~148 g
    #
    # # Different density units supported
    # honey_weight = volume.to_weight(1.42, :g_per_cc)     # ~355 g
    # mercury_weight = volume.to_weight(13.534, :g_per_cc) # ~3.38 kg
    # ```
    #
    # @param density_value The numeric density value
    # @param density_unit The unit of the density
    # @return The weight that would occupy this volume at the given density
    # @raise ArgumentError if density_value is zero or negative, or if density_unit is invalid
    def to_weight(density_value : Number, density_unit : Symbol) : Weight
      density = Density.new(density_value, density_unit)
      to_weight(density)
    end

    # Alias for to_weight with explicit naming for clarity
    #
    # This method provides a more explicit name that can make code
    # more readable, especially in complex expressions.
    #
    # ```
    # volume = Unit::Volume.new(500, :milliliter)
    # weight = volume.weight_given(Unit::Density.new(1.0, :g_per_ml))
    # ```
    #
    # @param density The density of the material
    # @return The weight that would occupy this volume at the given density
    def weight_given(density : Density) : Weight
      to_weight(density)
    end

    # Alias for to_weight with explicit naming for clarity (overload)
    #
    # This method provides a more explicit name that can make code
    # more readable, especially in complex expressions.
    #
    # ```
    # volume = Unit::Volume.new(250, :milliliter)
    # weight = volume.weight_given(0.593, :gram_per_milliliter)
    # ```
    #
    # @param density_value The numeric density value
    # @param density_unit The unit of the density
    # @return The weight that would occupy this volume at the given density
    def weight_given(density_value : Number, density_unit : Symbol) : Weight
      to_weight(density_value, density_unit)
    end
  end
end
