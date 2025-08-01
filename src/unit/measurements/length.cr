require "../measurement"
require "../conversion"

module Unit
  # Length measurement class with comprehensive unit support
  #
  # Supports both metric and imperial length units with precise conversions
  # using BigDecimal for accuracy. Meter is used as the base unit for all
  # conversions to maintain consistency and precision.
  #
  # Examples:
  #   Length.new(10.5, Length::Unit::Meter)
  #   Length.new(2.5, Length::Unit::Foot)
  #   Length.new(500, Length::Unit::Millimeter)
  class Length
    include Conversion
    # Comprehensive length unit enumeration
    #
    # Includes both metric units (meter-based) and imperial units (foot-based)
    # with common aliases for convenience.
    enum Unit
      # Metric units
      Meter
      Centimeter
      Millimeter
      Kilometer
      
      # Imperial units
      Inch
      Foot
      Yard
      Mile
      
      # Common aliases for convenience
      M = Meter
      Cm = Centimeter
      Mm = Millimeter
      Km = Kilometer
      In = Inch
      Ft = Foot
      Yd = Yard
      Mi = Mile
      
      # Returns true if this unit is part of the metric system
      def metric?
        case self
        when .meter?, .centimeter?, .millimeter?, .kilometer?
          true
        else
          false
        end
      end
      
      # Returns the standard symbol for this unit
      def symbol
        case self
        when .meter?
          "m"
        when .centimeter?
          "cm"
        when .millimeter?
          "mm"
        when .kilometer?
          "km"
        when .inch?
          "in"
        when .foot?
          "ft"
        when .yard?
          "yd"
        when .mile?
          "mi"
        else
          to_s.downcase
        end
      end
      
      # Returns the full name with proper pluralization
      def name(plural = false)
        base_name = case self
                   when .meter?
                     "meter"
                   when .centimeter?
                     "centimeter"
                   when .millimeter?
                     "millimeter"
                   when .kilometer?
                     "kilometer"
                   when .inch?
                     "inch"
                   when .foot?
                     "foot"
                   when .yard?
                     "yard"
                   when .mile?
                     "mile"
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
    
    # Conversion factors to meters (base unit)
    #
    # All values are stored as BigDecimal for maximum precision
    # Values are based on internationally accepted conversion standards
    CONVERSION_FACTORS = {
      Unit::Meter      => BigDecimal.new("1"),
      Unit::Centimeter => BigDecimal.new("0.01"),
      Unit::Millimeter => BigDecimal.new("0.001"),
      Unit::Kilometer  => BigDecimal.new("1000"),
      Unit::Inch       => BigDecimal.new("0.0254"),        # Exact conversion (international inch)
      Unit::Foot       => BigDecimal.new("0.3048"),        # Exact conversion (international foot)
      Unit::Yard       => BigDecimal.new("0.9144"),        # Exact conversion (3 feet)
      Unit::Mile       => BigDecimal.new("1609.344"),      # Exact conversion (5280 feet)
    }
    
    # Value stored as BigDecimal for precision
    getter value : BigDecimal
    
    # Unit of measurement
    getter unit : Unit
    
    # Creates a new length with the given value and unit
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
    
    # Returns the base unit for length measurements (meter)
    def self.base_unit
      Unit::Meter
    end
    
    # Returns the conversion factor for the given unit
    def self.conversion_factor(unit : Unit)
      CONVERSION_FACTORS[unit]
    end
    
    # Returns true if the given unit is metric
    def self.metric_unit?(unit : Unit)
      unit.metric?
    end
    
    # Returns the symbol for this length's unit
    def symbol
      @unit.symbol
    end
    
    # Returns the name of this length's unit
    def unit_name(plural = false)
      @unit.name(plural)
    end
    
    # Returns a readable string representation of the measurement
    def to_s(io : IO) : Nil
      io << @value << " " << @unit.to_s.downcase
    end
    
    # Returns a detailed string representation for debugging
    def inspect(io : IO) : Nil
      io << "Length(" << @value << ", " << @unit << ")"
    end
    
    # Equality comparison based on value and unit
    def ==(other : Length) : Bool
      @value == other.value && @unit == other.unit
    end
    
    # Hash function for use in Hash collections
    def hash(hasher)
      hasher = @value.hash(hasher)
      hasher = @unit.hash(hasher)
      hasher
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
  end
end