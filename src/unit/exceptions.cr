module Unit
  # Base exception class for all unit-related errors.
  # This provides a common ancestor for all domain-specific exceptions
  # in the Unit module, making it easy to catch all unit-related errors.
  #
  # Example:
  # ```
  # begin
  #   # Some unit operation
  # rescue ex : Unit::UnitError
  #   # Handle any unit-related error
  # end
  # ```
  class UnitError < Exception
  end

  # Exception raised when a conversion between units fails.
  # This typically happens when attempting to convert between incompatible
  # measurement types (e.g., weight to length).
  #
  # Example:
  # ```
  # begin
  #   weight = Weight.new(10, :kg)
  #   length = Length.new(5, :m)
  #   # This would raise ConversionError:
  #   # weight + length
  # rescue ex : Unit::ConversionError
  #   puts ex.message # => "Cannot convert from Weight to Length: Incompatible measurement types"
  # end
  # ```
  class ConversionError < UnitError
    getter from_unit : String
    getter to_unit : String
    getter reason : String?

    def initialize(@from_unit : String, @to_unit : String, @reason : String? = nil)
      message = "Cannot convert from #{@from_unit} to #{@to_unit}"
      message += ": #{@reason}" if @reason
      super(message)
    end

    # Alternative constructor that accepts unit types directly
    def self.new(from_unit, to_unit, reason = nil)
      new(from_unit.to_s, to_unit.to_s, reason)
    end

    # Factory method for incompatible type conversions
    def self.incompatible_types(from_type : T.class, to_type : U.class) forall T, U
      new(from_type.name, to_type.name, "Incompatible measurement types")
    end
  end

  # Exception raised when parsing a string into a measurement fails.
  # This can occur due to invalid format, unrecognized units, or malformed input.
  #
  # Example:
  # ```
  # begin
  #   Weight.parse("10 invalid_unit")
  # rescue ex : Unit::ParseError
  #   puts ex.message # => "Cannot parse '10 invalid_unit' as measurement: Unknown unit 'invalid_unit'"
  # end
  # ```
  class ParseError < UnitError
    getter input : String
    getter reason : String?

    def initialize(@input : String, @reason : String? = nil)
      message = "Cannot parse '#{@input}' as measurement"
      message += ": #{@reason}" if @reason
      super(message)
    end

    # Factory method for unknown unit errors
    def self.unknown_unit(input : String, unit : String)
      new(input, "Unknown unit '#{unit}'")
    end

    # Factory method for invalid format errors
    def self.invalid_format(input : String)
      new(input, "Invalid format. Expected: '<value> <unit>' (e.g., '10 kg')")
    end
  end

  # Exception raised when a validation constraint is violated.
  # This can happen when values are outside acceptable ranges or
  # when business rules are violated.
  #
  # Example:
  # ```
  # begin
  #   # If negative weights are not allowed:
  #   Weight.new(-5, :kg)
  # rescue ex : Unit::ValidationError
  #   puts ex.message # => "Weight cannot be negative"
  # end
  # ```
  class ValidationError < UnitError
    def initialize(message : String)
      super(message)
    end
  end

  # Exception raised when arithmetic operations fail.
  # This includes operations like adding incompatible units,
  # division by zero, or other arithmetic constraints.
  #
  # Example:
  # ```
  # begin
  #   weight = Weight.new(10, :kg)
  #   weight / 0
  # rescue ex : Unit::ArithmeticError
  #   puts ex.message # => "Arithmetic operation 'division' failed: Division by zero"
  # end
  # ```
  class ArithmeticError < UnitError
    getter operation : String
    getter reason : String

    def initialize(@operation : String, @reason : String)
      super("Arithmetic operation '#{@operation}' failed: #{@reason}")
    end

    # Factory method for division by zero errors
    def self.division_by_zero
      new("division", "Division by zero")
    end

    # Factory method for incompatible operand errors
    def self.incompatible_operands(operation : String, left_type : String, right_type : String)
      new(operation, "Incompatible operands: #{left_type} and #{right_type}")
    end
  end

  # Module providing exception helper methods
  module ExceptionHelpers
    # Raises a ConversionError for incompatible types
    def raise_incompatible_types(from_type : T.class, to_type : U.class) forall T, U
      raise ConversionError.incompatible_types(from_type, to_type)
    end

    # Raises a ParseError for unknown units
    def raise_unknown_unit(input : String, unit : String)
      raise ParseError.unknown_unit(input, unit)
    end

    # Raises an ArithmeticError for division by zero
    def raise_division_by_zero
      raise ArithmeticError.division_by_zero
    end
  end
end
