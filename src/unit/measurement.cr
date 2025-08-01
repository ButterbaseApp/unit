require "big"
require "json"
require "yaml"
require "./arithmetic"
require "./conversion"
require "./formatter"
require "./converters/big_decimal_converter"
require "./converters/enum_converter"

module Unit
  # Generic measurement class with phantom types for compile-time type safety
  #
  # This class provides the foundation for all measurement types in the Unit library.
  # It uses Crystal's phantom types to ensure type safety at compile time, preventing
  # operations between incompatible measurement types.
  #
  # The class is parameterized by:
  # - `T`: The measurement type (e.g., Weight, Length, Volume)
  # - `U`: The unit enum type specific to that measurement
  #
  # ## Type Safety
  #
  # The phantom type system prevents mixing incompatible measurements:
  #
  # ```
  # weight = Unit::Weight.new(10, :kilogram)
  # length = Unit::Length.new(5, :meter)
  # # weight + length  # Compile error! Cannot add Weight to Length
  # ```
  #
  # ## Precision
  #
  # All values are stored internally as `BigDecimal` to maintain precision across
  # conversions and arithmetic operations.
  #
  # ## Examples
  #
  # ```
  # # Creating measurements
  # weight = Unit::Weight.new(5.5, :kilogram)
  # length = Unit::Length.new(100, :centimeter)
  #
  # # Converting units
  # pounds = weight.convert_to(:pound)
  # meters = length.to(:meter)
  #
  # # Arithmetic operations
  # total = weight + Unit::Weight.new(10, :pound)
  # double = weight * 2
  # ```
  class Measurement(T, U)
    include Arithmetic
    include Conversion
    include Formatter

    # The numeric value of the measurement, stored as BigDecimal for precision.
    #
    # ```
    # weight = Unit::Weight.new(5.5, :kilogram)
    # weight.value # => BigDecimal("5.5")
    # ```
    getter value : BigDecimal

    # The unit of measurement as an enum value.
    #
    # ```
    # weight = Unit::Weight.new(5.5, :kilogram)
    # weight.unit # => Unit::Weight::Unit::Kilogram
    # ```
    getter unit : U

    # Creates a new measurement with the given value and unit.
    #
    # The value is automatically converted to `BigDecimal` for precision preservation.
    # This constructor accepts any numeric type supported by Crystal.
    #
    # ## Parameters
    # - `value`: The numeric value (Int32, Int64, Float32, Float64, BigDecimal, BigRational)
    # - `unit`: The unit enum value or symbol
    #
    # ## Examples
    #
    # ```
    # # Using enum values
    # Unit::Weight.new(10, Unit::Weight::Unit::Kilogram)
    #
    # # Using symbols (convenient shorthand)
    # Unit::Weight.new(10, :kilogram)
    #
    # # Various numeric types
    # Unit::Weight.new(10_i32, :kilogram)                 # Int32
    # Unit::Weight.new(10.5_f64, :kilogram)               # Float64
    # Unit::Weight.new(BigDecimal.new("10.5"), :kilogram) # BigDecimal
    # ```
    #
    # ## Raises
    # - `ArgumentError` if value is NaN
    # - `ArgumentError` if value is infinite
    def initialize(value : Number, @unit : U)
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

    # Returns a detailed string representation for debugging.
    #
    # Shows the measurement's type parameters and internal structure, useful for
    # development and debugging purposes.
    #
    # ```
    # weight = Unit::Weight.new(5.5, :kilogram)
    # weight.inspect # => "Measurement(Unit::Weight, Unit::Weight::Unit)(5.5, Kilogram)"
    # ```
    def inspect(io : IO) : Nil
      io << "Measurement(" << T << ", " << U << ")"
      io << "(" << @value << ", " << @unit << ")"
    end

    # Compares two measurements for equality.
    #
    # Two measurements are considered equal if they have the same value and unit.
    # This method only compares measurements of the same type due to phantom typing.
    #
    # Note: For comparing measurements with different units, use the comparison
    # operators (>, <, etc.) which handle unit conversion automatically.
    #
    # ```
    # kg1 = Unit::Weight.new(1, :kilogram)
    # kg2 = Unit::Weight.new(1, :kilogram)
    # g1000 = Unit::Weight.new(1000, :gram)
    #
    # kg1 == kg2   # => true (same value and unit)
    # kg1 == g1000 # => false (different units, use comparison operators instead)
    # ```
    def ==(other : Measurement(T, U)) : Bool
      @value == other.value && @unit == other.unit
    end

    # Generates a hash value for use in Hash collections.
    #
    # The hash is based on both the value and unit to maintain consistency
    # with the equality operator.
    #
    # ```
    # weights = {} of Unit::Weight => String
    # weight = Unit::Weight.new(5.5, :kilogram)
    # weights[weight] = "medium"
    # ```
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

    # Serializes the measurement to JSON format.
    #
    # The value is stored as a string to preserve BigDecimal precision,
    # and the unit is stored as its string representation.
    #
    # ```
    # weight = Unit::Weight.new(5.5, :kilogram)
    # weight.to_json # => {"value":"5.5","unit":"kilogram"}
    # ```
    def to_json(json : JSON::Builder) : Nil
      json.object do
        json.field "value" do
          BigDecimalConverter.to_json(@value, json)
        end
        json.field "unit" do
          EnumConverter(U).to_json(@unit, json)
        end
      end
    end

    # Serializes the measurement to YAML format.
    #
    # The value is stored as a string to preserve BigDecimal precision,
    # and the unit is stored as its string representation.
    #
    # ```
    # weight = Unit::Weight.new(5.5, :kilogram)
    # weight.to_yaml # => "---\nvalue: '5.5'\nunit: kilogram\n"
    # ```
    def to_yaml(yaml : YAML::Nodes::Builder) : Nil
      yaml.mapping do
        yaml.scalar "value"
        BigDecimalConverter.to_yaml(@value, yaml)
        yaml.scalar "unit"
        EnumConverter(U).to_yaml(@unit, yaml)
      end
    end
  end
end
