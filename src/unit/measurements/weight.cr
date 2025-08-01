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
  # Supports both metric and imperial weight units with precise conversions
  # using BigDecimal for accuracy. Gram is used as the base unit for all
  # conversions to maintain consistency and precision.
  #
  # Examples:
  #   Weight.new(10.5, Weight::Unit::Kilogram)
  #   Weight.new(2.5, Weight::Unit::Pound)
  #   Weight.new(500, Weight::Unit::Gram)
  class Weight
    include Conversion
    include Arithmetic
    include Comparison
    include Formatter
    include Comparable(self)
    # Comprehensive weight unit enumeration
    #
    # Includes both metric units (gram-based) and imperial units (pound-based)
    # with common aliases for convenience.
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
      G = Gram
      Kg = Kilogram
      Mg = Milligram
      T = Tonne
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
      Unit::Gram      => BigDecimal.new("1"),
      Unit::Kilogram  => BigDecimal.new("1000"),
      Unit::Milligram => BigDecimal.new("0.001"),
      Unit::Tonne     => BigDecimal.new("1000000"),
      Unit::Pound     => BigDecimal.new("453.59237"),        # Exact conversion
      Unit::Ounce     => BigDecimal.new("28.349523125"),     # Exact conversion (1/16 lb)
      Unit::Slug      => BigDecimal.new("14593.903"),        # Based on 1 slug = 32.174 lb
    }
    
    # Value stored as BigDecimal for precision
    getter value : BigDecimal
    
    # Unit of measurement
    getter unit : Unit
    
    # Creates a new weight with the given value and unit
    def initialize(value : Number, @unit : Unit)
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
    
    # Returns the base unit for weight measurements (gram)
    def self.base_unit
      Unit::Gram
    end
    
    # Returns the conversion factor for the given unit
    def self.conversion_factor(unit : Unit)
      CONVERSION_FACTORS[unit]
    end
    
    # Returns true if the given unit is metric
    def self.metric_unit?(unit : Unit)
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
  end
end