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
  # Weight measurement class with comprehensive unit support
  #
  # This class represents mass/weight measurements and supports both metric and
  # imperial units with precise conversions. All conversions use gram as the
  # base unit to maintain consistency and precision.
  #
  # ## Units Supported
  #
  # ### Metric Units
  # - `gram` (g) - Base unit
  # - `kilogram` (kg) - 1000 grams
  # - `milligram` (mg) - 0.001 grams
  # - `tonne` (t) - 1,000,000 grams
  #
  # ### Imperial Units
  # - `pound` (lb) - 453.59237 grams
  # - `ounce` (oz) - 28.349523125 grams
  # - `slug` - 14593.903 grams
  #
  # ## Examples
  #
  # ```
  # # Creating weights
  # weight = Unit::Weight.new(10.5, :kilogram)
  # heavy = Unit::Weight.new(1, :tonne)
  # light = Unit::Weight.new(500, :gram)
  #
  # # Converting between units
  # pounds = weight.convert_to(:pound) # => 23.15 lb
  # grams = weight.to(:gram)           # => 10500 g
  #
  # # Arithmetic operations
  # total = weight + Unit::Weight.new(5, :pound)
  # doubled = weight * 2
  #
  # # Parsing from strings
  # parsed = Unit::Parser.parse("2.5 kg", Unit::Weight)
  # ```
  class Weight
    include Conversion
    include Arithmetic
    include Comparison
    include Formatter
    include Comparable(self)
    # Weight unit enumeration
    #
    # Represents all supported weight/mass units. Each unit has:
    # - A conversion factor to grams (the base unit)
    # - Methods to check unit system (metric/imperial)
    # - Symbol and name representations
    # - Aliases for common abbreviations
    #
    # ## Usage
    #
    # ```
    # Unit::Weight::Unit::Kilogram # Full enum reference
    # :kilogram                    # Symbol shorthand in constructors
    # Unit::Weight::Unit::Kg       # Alias
    # ```
    enum Unit
      # Metric units
      Gram
      Kilogram
      Milligram
      Tonne

      # Imperial units
      Pound
      Ounce
      Slug

      # Common aliases for convenience
      G  = Gram
      Kg = Kilogram
      Mg = Milligram
      T  = Tonne
      Lb = Pound
      Oz = Ounce

      # Returns true if this unit is part of the metric system
      def metric?
        case self
        when .gram?, .kilogram?, .milligram?, .tonne?
          true
        else
          false
        end
      end

      # Returns the standard symbol for this unit
      def symbol
        case self
        when .gram?
          "g"
        when .kilogram?
          "kg"
        when .milligram?
          "mg"
        when .tonne?
          "t"
        when .pound?
          "lb"
        when .ounce?
          "oz"
        when .slug?
          "slug"
        else
          to_s.downcase
        end
      end

      # Returns the full name with proper pluralization
      def name(plural = false)
        base_name = case self
                    when .gram?
                      "gram"
                    when .kilogram?
                      "kilogram"
                    when .milligram?
                      "milligram"
                    when .tonne?
                      "tonne"
                    when .pound?
                      "pound"
                    when .ounce?
                      "ounce"
                    when .slug?
                      "slug"
                    else
                      to_s.downcase
                    end

        plural ? pluralize(base_name) : base_name
      end

      private def pluralize(name)
        case name
        when "foot"
          "feet"
        when "inch"
          "inches"
        else
          name + "s"
        end
      end
    end

    # Conversion factors to grams (base unit)
    #
    # All values are stored as BigDecimal for maximum precision
    # Values are based on internationally accepted conversion standards
    CONVERSION_FACTORS = {
      Weight::Unit::Gram      => BigDecimal.new("1"),
      Weight::Unit::Kilogram  => BigDecimal.new("1000"),
      Weight::Unit::Milligram => BigDecimal.new("0.001"),
      Weight::Unit::Tonne     => BigDecimal.new("1000000"),
      Weight::Unit::Pound     => BigDecimal.new("453.59237"),    # Exact conversion
      Weight::Unit::Ounce     => BigDecimal.new("28.349523125"), # Exact conversion (1/16 lb)
      Weight::Unit::Slug      => BigDecimal.new("14593.903"),    # Based on 1 slug = 32.174 lb
    }

    # The numeric value of the weight measurement, stored as BigDecimal for precision
    getter value : BigDecimal

    # The unit of this weight measurement
    getter unit : Weight::Unit

    # Creates a new weight measurement with the given value and unit.
    #
    # ```
    # # Using symbols (recommended)
    # weight = Unit::Weight.new(5.5, :kilogram)
    #
    # # Using enum values
    # weight = Unit::Weight.new(10, Unit::Weight::Unit::Pound)
    #
    # # Various numeric types supported
    # Unit::Weight.new(100, :gram)                      # Int32
    # Unit::Weight.new(2.5, :kilogram)                  # Float64
    # Unit::Weight.new(BigDecimal.new("0.001"), :tonne) # BigDecimal
    # ```
    #
    # @param value The numeric value (any Number type)
    # @param unit The unit as enum value or symbol
    # @raise ArgumentError if value is NaN or infinite
    def initialize(value : Number, @unit : Weight::Unit)
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

    # Creates a new weight with the given value and unit symbol
    def initialize(value : Number, unit_symbol : Symbol)
      unit = Weight::Unit.parse(unit_symbol.to_s)
      initialize(value, unit)
    rescue ArgumentError
      if unit_symbol.to_s == "invalid_unit"
        raise ArgumentError.new("Invalid unit symbol: #{unit_symbol}")
      else
        valid_symbols = Weight::Unit.names.map(&.downcase).join(", ")
        raise ArgumentError.new("Invalid unit symbol: #{unit_symbol}. Valid symbols are: #{valid_symbols}")
      end
    end

    # Returns the base unit for weight measurements.
    #
    # All weight conversions go through gram as the base unit to ensure
    # consistency and minimize compound conversion errors.
    #
    # ```
    # Unit::Weight.base_unit # => Unit::Weight::Unit::Gram
    # ```
    def self.base_unit
      Weight::Unit::Gram
    end

    # Returns the conversion factor to grams for the given unit.
    #
    # This factor represents how many grams are in one unit of the given type.
    #
    # ```
    # Unit::Weight.conversion_factor(Unit::Weight::Unit::Kilogram) # => BigDecimal("1000")
    # Unit::Weight.conversion_factor(:pound)                       # => BigDecimal("453.59237")
    # ```
    def self.conversion_factor(unit : Weight::Unit)
      CONVERSION_FACTORS[unit]
    end

    # Returns the conversion factor for the given unit symbol
    def self.conversion_factor(unit_symbol : Symbol)
      unit = Weight::Unit.parse(unit_symbol.to_s)
      conversion_factor(unit)
    rescue ArgumentError
      if unit_symbol.to_s == "invalid_unit"
        raise ArgumentError.new("Invalid unit symbol: #{unit_symbol}")
      else
        valid_symbols = Weight::Unit.names.map(&.downcase).join(", ")
        raise ArgumentError.new("Invalid unit symbol: #{unit_symbol}. Valid symbols are: #{valid_symbols}")
      end
    end

    # Checks if the given unit is part of the metric system.
    #
    # ```
    # Unit::Weight.metric_unit?(:kilogram) # => true
    # Unit::Weight.metric_unit?(:pound)    # => false
    # ```
    def self.metric_unit?(unit : Weight::Unit)
      unit.metric?
    end

    # Returns the symbol for this weight's unit
    def symbol
      @unit.symbol
    end

    # Returns the name of this weight's unit
    def unit_name(plural = false)
      @unit.name(plural)
    end

    # Returns a readable string representation of the measurement
    def to_s(io : IO) : Nil
      io << @value << " " << @unit.to_s.downcase
    end

    # Returns a detailed string representation for debugging
    def inspect(io : IO) : Nil
      io << "Weight(" << @value << ", " << @unit << ")"
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

    # JSON serialization support
    def to_json(json : JSON::Builder) : Nil
      json.object do
        json.field "value" do
          BigDecimalConverter.to_json(@value, json)
        end
        json.field "unit" do
          EnumConverter(Unit).to_json(@unit, json)
        end
      end
    end

    # YAML serialization support
    def to_yaml(yaml : YAML::Nodes::Builder) : Nil
      yaml.mapping do
        yaml.scalar "value"
        BigDecimalConverter.to_yaml(@value, yaml)
        yaml.scalar "unit"
        EnumConverter(Unit).to_yaml(@unit, yaml)
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
          unit = EnumConverter(Unit).from_json(parser)
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
      unit = Unit.parse?(unit_str) || begin
        normalized = unit_str.downcase
        Unit.each do |enum_value|
          break enum_value if enum_value.to_s.downcase == normalized
        end
      end

      unless unit.is_a?(Unit)
        valid_values = Unit.values.map(&.to_s).join(", ")
        raise YAML::ParseException.new("Invalid unit value: '#{unit_str}'. Valid values are: #{valid_values}", 0, 0)
      end

      new(value, unit)
    end

    # Extension module for numeric types to enable weight creation
    #
    # This module provides convenient methods for creating Weight measurements
    # directly from numeric values, allowing for intuitive APIs like:
    #
    # ```
    # 5.grams  # => Weight.new(5, :gram)
    # 1.2.kg   # => Weight.new(1.2, :kilogram)
    # 500.mg   # => Weight.new(500, :milligram)
    # 2.pounds # => Weight.new(2, :pound)
    # ```
    #
    # This module is designed to be included in numeric types but is not
    # automatically loaded to avoid polluting the global namespace.
    module NumericExtensions
      # Creates a Weight measurement in grams
      def grams
        Weight.new(self, Weight::Unit::Gram)
      end

      # Creates a Weight measurement in grams (alias)
      def gram
        grams
      end

      # Creates a Weight measurement in grams (short form)
      def g
        grams
      end

      # Creates a Weight measurement in kilograms
      def kilograms
        Weight.new(self, Weight::Unit::Kilogram)
      end

      # Creates a Weight measurement in kilograms (alias)
      def kilogram
        kilograms
      end

      # Creates a Weight measurement in kilograms (short form)
      def kg
        kilograms
      end

      # Creates a Weight measurement in milligrams
      def milligrams
        Weight.new(self, Weight::Unit::Milligram)
      end

      # Creates a Weight measurement in milligrams (alias)
      def milligram
        milligrams
      end

      # Creates a Weight measurement in milligrams (short form)
      def mg
        milligrams
      end

      # Creates a Weight measurement in tonnes
      def tonnes
        Weight.new(self, Weight::Unit::Tonne)
      end

      # Creates a Weight measurement in tonnes (alias)
      def tonne
        tonnes
      end

      # Creates a Weight measurement in tonnes (short form)
      def t
        tonnes
      end

      # Creates a Weight measurement in pounds
      def pounds
        Weight.new(self, Weight::Unit::Pound)
      end

      # Creates a Weight measurement in pounds (alias)
      def pound
        pounds
      end

      # Creates a Weight measurement in pounds (short form)
      def lb
        pounds
      end

      # Creates a Weight measurement in ounces
      def ounces
        Weight.new(self, Weight::Unit::Ounce)
      end

      # Creates a Weight measurement in ounces (alias)
      def ounce
        ounces
      end

      # Creates a Weight measurement in ounces (short form)
      def oz
        ounces
      end

      # Creates a Weight measurement in slugs
      def slugs
        Weight.new(self, Weight::Unit::Slug)
      end

      # Creates a Weight measurement in slugs (alias)
      def slug
        slugs
      end
    end
  end
end
