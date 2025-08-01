require "../measurement"
require "../conversion"

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
      L = Liter
      Ml = Milliliter
      Gal = Gallon
      Qt = Quart
      Pt = Pint
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
      Unit::Liter      => BigDecimal.new("1"),
      Unit::Milliliter => BigDecimal.new("0.001"),
      Unit::Gallon     => BigDecimal.new("3.785411784"),        # US liquid gallon
      Unit::Quart      => BigDecimal.new("0.946352946"),        # US liquid quart (1/4 gallon)
      Unit::Pint       => BigDecimal.new("0.473176473"),        # US liquid pint (1/8 gallon)
      Unit::Cup        => BigDecimal.new("0.2365882365"),       # US cup (1/16 gallon)
      Unit::FluidOunce => BigDecimal.new("0.0295735295625"),    # US fluid ounce (1/128 gallon)
    }
    
    # Value stored as BigDecimal for precision
    getter value : BigDecimal
    
    # Unit of measurement
    getter unit : Unit
    
    # Creates a new volume with the given value and unit
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
    
    # Returns the base unit for volume measurements (liter)
    def self.base_unit
      Unit::Liter
    end
    
    # Returns the conversion factor for the given unit
    def self.conversion_factor(unit : Unit)
      CONVERSION_FACTORS[unit]
    end
    
    # Returns true if the given unit is metric
    def self.metric_unit?(unit : Unit)
      unit.metric?
    end
    
    # Returns true if the given unit is a US liquid measurement
    def self.us_liquid_unit?(unit : Unit)
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
    
    # Equality comparison based on value and unit
    def ==(other : Volume) : Bool
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
      
      # For volume measurements, we might want to reject negative values in cooking contexts
      # This is left flexible but could be enhanced for specific use cases
    end
  end
end