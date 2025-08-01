require "../spec_helper"

# Test helper class for ExceptionHelpers module
class ExceptionHelperTest
  include Unit::ExceptionHelpers
end

describe Unit do
  describe "Exception Classes" do
    describe Unit::UnitError do
      it "is the base exception for all unit errors" do
        error = Unit::UnitError.new("Base error")
        error.should be_a(Exception)
        error.message.should eq("Base error")
      end

      it "can be caught as a general unit error" do
        expect_raises(Unit::UnitError) do
          raise Unit::UnitError.new("Test error")
        end
      end
    end

    describe Unit::ConversionError do
      it "inherits from UnitError" do
        error = Unit::ConversionError.new("kg", "m", "Different measurement types")
        error.should be_a(Unit::UnitError)
      end

      it "creates proper error message without reason" do
        error = Unit::ConversionError.new("kg", "m")
        error.message.should eq("Cannot convert from kg to m")
        error.from_unit.should eq("kg")
        error.to_unit.should eq("m")
        error.reason.should be_nil
      end

      it "creates proper error message with reason" do
        error = Unit::ConversionError.new("kg", "m", "Different measurement types")
        error.message.should eq("Cannot convert from kg to m: Different measurement types")
        error.reason.should eq("Different measurement types")
      end

      it "works with unit types directly" do
        error = Unit::ConversionError.new(Unit::Weight::Unit::Kilogram, Unit::Length::Unit::Meter, "Incompatible")
        error.message.should eq("Cannot convert from Kilogram to Meter: Incompatible")
      end

      it "has factory method for incompatible types" do
        error = Unit::ConversionError.incompatible_types(Unit::Weight, Unit::Length)
        error.message.should eq("Cannot convert from Unit::Weight to Unit::Length: Incompatible measurement types")
      end
    end

    describe Unit::ParseError do
      it "inherits from UnitError" do
        error = Unit::ParseError.new("invalid input")
        error.should be_a(Unit::UnitError)
      end

      it "creates proper error message without reason" do
        error = Unit::ParseError.new("10 xyz")
        error.message.should eq("Cannot parse '10 xyz' as measurement")
        error.input.should eq("10 xyz")
        error.reason.should be_nil
      end

      it "creates proper error message with reason" do
        error = Unit::ParseError.new("10 xyz", "Unknown unit")
        error.message.should eq("Cannot parse '10 xyz' as measurement: Unknown unit")
        error.reason.should eq("Unknown unit")
      end

      it "has factory method for unknown unit" do
        error = Unit::ParseError.unknown_unit("10 xyz", "xyz")
        error.message.should eq("Cannot parse '10 xyz' as measurement: Unknown unit 'xyz'")
      end

      it "has factory method for invalid format" do
        error = Unit::ParseError.invalid_format("invalid")
        error.message.should eq("Cannot parse 'invalid' as measurement: Invalid format. Expected: '<value> <unit>' (e.g., '10 kg')")
      end
    end

    describe Unit::ValidationError do
      it "inherits from UnitError" do
        error = Unit::ValidationError.new("Value must be positive")
        error.should be_a(Unit::UnitError)
      end

      it "creates proper error message" do
        error = Unit::ValidationError.new("Weight cannot be negative")
        error.message.should eq("Weight cannot be negative")
      end
    end

    describe Unit::ArithmeticError do
      it "inherits from UnitError" do
        error = Unit::ArithmeticError.new("addition", "Incompatible units")
        error.should be_a(Unit::UnitError)
      end

      it "creates proper error message" do
        error = Unit::ArithmeticError.new("division", "Cannot divide by zero")
        error.message.should eq("Arithmetic operation 'division' failed: Cannot divide by zero")
        error.operation.should eq("division")
        error.reason.should eq("Cannot divide by zero")
      end

      it "has factory method for division by zero" do
        error = Unit::ArithmeticError.division_by_zero
        error.message.should eq("Arithmetic operation 'division' failed: Division by zero")
      end

      it "has factory method for incompatible operands" do
        error = Unit::ArithmeticError.incompatible_operands("addition", "Weight", "Length")
        error.message.should eq("Arithmetic operation 'addition' failed: Incompatible operands: Weight and Length")
      end
    end

    describe Unit::ExceptionHelpers do
      it "provides helper methods for raising exceptions" do
        helper = ExceptionHelperTest.new

        expect_raises(Unit::ConversionError, "Cannot convert from Unit::Weight to Unit::Length: Incompatible measurement types") do
          helper.raise_incompatible_types(Unit::Weight, Unit::Length)
        end

        expect_raises(Unit::ParseError, "Cannot parse '10 xyz' as measurement: Unknown unit 'xyz'") do
          helper.raise_unknown_unit("10 xyz", "xyz")
        end

        expect_raises(Unit::ArithmeticError, "Arithmetic operation 'division' failed: Division by zero") do
          helper.raise_division_by_zero
        end
      end
    end

    # Test exception hierarchy
    describe "Exception Hierarchy" do
      it "allows catching specific exceptions" do
        expect_raises(Unit::ConversionError) do
          raise Unit::ConversionError.new("kg", "m")
        end
      end

      it "allows catching all unit errors with UnitError" do
        expect_raises(Unit::UnitError) do
          raise Unit::ParseError.new("invalid")
        end

        expect_raises(Unit::UnitError) do
          raise Unit::ValidationError.new("invalid value")
        end

        expect_raises(Unit::UnitError) do
          raise Unit::ArithmeticError.new("operation", "reason")
        end
      end

      it "preserves standard exception behavior" do
        begin
          raise Unit::ConversionError.new("kg", "m", "Test")
        rescue ex : Unit::ConversionError
          ex.backtrace.should_not be_nil
          ex.cause.should be_nil
        end
      end
    end
  end
end
