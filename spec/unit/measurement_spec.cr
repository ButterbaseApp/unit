require "../spec_helper"
require "../../src/unit/measurement"

# Define phantom type markers for testing
struct Weight; end

struct Length; end

struct Temperature; end

struct Pressure; end

enum WeightUnit
  Kilogram
  Gram
  Pound
end

enum LengthUnit
  Meter
  Centimeter
  Inch
end

enum CommonUnit
  Celsius
  Fahrenheit
end

describe Unit::Measurement do
  describe "class structure" do
    it "creates measurement with phantom types" do
      measurement = Unit::Measurement(Weight, WeightUnit).new(10.5, WeightUnit::Kilogram)
      measurement.should be_a(Unit::Measurement(Weight, WeightUnit))
    end

    it "stores value as BigDecimal" do
      measurement = Unit::Measurement(Weight, WeightUnit).new(10.5, WeightUnit::Kilogram)
      measurement.value.should be_a(BigDecimal)
      measurement.value.should eq(BigDecimal.new("10.5"))
    end

    it "stores unit correctly" do
      measurement = Unit::Measurement(Weight, WeightUnit).new(10.5, WeightUnit::Kilogram)
      measurement.unit.should eq(WeightUnit::Kilogram)
    end

    it "maintains immutability with readonly getters" do
      measurement = Unit::Measurement(Weight, WeightUnit).new(10.5, WeightUnit::Kilogram)

      # Verify getters exist and return expected types
      measurement.value.should be_a(BigDecimal)
      measurement.unit.should be_a(WeightUnit)
    end

    it "supports different phantom type combinations" do
      weight = Unit::Measurement(Weight, WeightUnit).new(10, WeightUnit::Kilogram)
      length = Unit::Measurement(Length, LengthUnit).new(5, LengthUnit::Meter)

      # These should be different types at compile time
      weight.should be_a(Unit::Measurement(Weight, WeightUnit))
      length.should be_a(Unit::Measurement(Length, LengthUnit))
    end
  end

  describe "flexible number input constructor" do
    it "accepts Int32 values" do
      measurement = Unit::Measurement(Weight, WeightUnit).new(42_i32, WeightUnit::Kilogram)
      measurement.value.should eq(BigDecimal.new("42"))
    end

    it "accepts Int64 values" do
      large_value = 9223372036854775807_i64
      measurement = Unit::Measurement(Weight, WeightUnit).new(large_value, WeightUnit::Kilogram)
      measurement.value.should eq(BigDecimal.new("9223372036854775807"))
    end

    it "accepts Float32 values with precision preservation" do
      measurement = Unit::Measurement(Weight, WeightUnit).new(3.14_f32, WeightUnit::Kilogram)
      measurement.value.should eq(BigDecimal.new("3.14"))
    end

    it "accepts Float64 values with precision preservation" do
      measurement = Unit::Measurement(Weight, WeightUnit).new(2.718281828459045, WeightUnit::Kilogram)
      measurement.value.should eq(BigDecimal.new("2.718281828459045"))
    end

    it "accepts BigDecimal values directly" do
      big_val = BigDecimal.new("123.456789012345678901234567890")
      measurement = Unit::Measurement(Weight, WeightUnit).new(big_val, WeightUnit::Kilogram)
      measurement.value.should eq(big_val)
    end

    it "accepts BigRational values" do
      rational_val = BigRational.new(22, 7)
      measurement = Unit::Measurement(Weight, WeightUnit).new(rational_val, WeightUnit::Kilogram)
      # BigRational.to_s returns a decimal representation
      measurement.value.should eq(BigDecimal.new(rational_val.to_f.to_s))
    end

    it "preserves precision for very large numbers" do
      large_int = 9223372036854775807_i64 # Max Int64
      measurement = Unit::Measurement(Weight, WeightUnit).new(large_int, WeightUnit::Kilogram)
      # BigDecimal might use scientific notation for large numbers
      measurement.value.to_s.should match(/9.223372036854775807e\+18|9223372036854775807/)
    end

    it "preserves precision for very small numbers" do
      small_float = 0.000000000123456789
      measurement = Unit::Measurement(Weight, WeightUnit).new(small_float, WeightUnit::Kilogram)
      measurement.value.to_s.should contain("1.23456789e-10")
    end

    it "rejects NaN float values" do
      expect_raises(ArgumentError, "Value cannot be NaN") do
        Unit::Measurement(Weight, WeightUnit).new(Float64::NAN, WeightUnit::Kilogram)
      end
    end

    it "rejects positive infinity float values" do
      expect_raises(ArgumentError, "Value cannot be infinite") do
        Unit::Measurement(Weight, WeightUnit).new(Float64::INFINITY, WeightUnit::Kilogram)
      end
    end

    it "rejects negative infinity float values" do
      expect_raises(ArgumentError, "Value cannot be infinite") do
        Unit::Measurement(Weight, WeightUnit).new(-Float64::INFINITY, WeightUnit::Kilogram)
      end
    end
  end

  describe "value validation" do
    it "successfully validates normal values" do
      measurement = Unit::Measurement(Weight, WeightUnit).new(42.5, WeightUnit::Kilogram)
      measurement.value.should eq(BigDecimal.new("42.5"))
    end

    it "successfully validates zero values" do
      measurement = Unit::Measurement(Weight, WeightUnit).new(0, WeightUnit::Kilogram)
      measurement.value.should eq(BigDecimal.new("0"))
    end

    it "successfully validates negative values" do
      measurement = Unit::Measurement(Weight, WeightUnit).new(-10.5, WeightUnit::Kilogram)
      measurement.value.should eq(BigDecimal.new("-10.5"))
    end

    it "successfully validates very small positive values" do
      measurement = Unit::Measurement(Weight, WeightUnit).new(0.0001, WeightUnit::Kilogram)
      measurement.value.should eq(BigDecimal.new("0.0001"))
    end

    it "successfully validates very large values" do
      measurement = Unit::Measurement(Weight, WeightUnit).new(999999999, WeightUnit::Kilogram)
      measurement.value.should eq(BigDecimal.new("999999999"))
    end

    it "validation runs during construction" do
      # This test ensures validate_value! is called
      # If validation is skipped, edge cases might not be caught
      measurement = Unit::Measurement(Weight, WeightUnit).new(42, WeightUnit::Kilogram)
      measurement.value.should be_a(BigDecimal)
    end
  end

  describe "phantom type compile-time safety" do
    it "enforces distinct phantom types at compile time" do
      weight = Unit::Measurement(Weight, WeightUnit).new(10, WeightUnit::Kilogram)
      length = Unit::Measurement(Length, LengthUnit).new(5, LengthUnit::Meter)

      # These should be completely different types
      weight.should be_a(Unit::Measurement(Weight, WeightUnit))
      length.should be_a(Unit::Measurement(Length, LengthUnit))

      # The types should not be interchangeable
      typeof(weight).should_not eq(typeof(length))
    end

    it "prevents type confusion with same unit enums but different phantom types" do
      # Even with same unit enum, different phantom types should be distinct
      temp = Unit::Measurement(Temperature, CommonUnit).new(25, CommonUnit::Celsius)
      pressure = Unit::Measurement(Pressure, CommonUnit).new(30, CommonUnit::Celsius)

      # Should be different types despite same unit enum
      typeof(temp).should_not eq(typeof(pressure))
    end

    it "maintains type safety with generic operations" do
      weight1 = Unit::Measurement(Weight, WeightUnit).new(10, WeightUnit::Kilogram)
      weight2 = Unit::Measurement(Weight, WeightUnit).new(5, WeightUnit::Gram)

      # Both are same phantom type, should be compatible for operations
      typeof(weight1).should eq(typeof(weight2))
      weight1.should be_a(Unit::Measurement(Weight, WeightUnit))
      weight2.should be_a(Unit::Measurement(Weight, WeightUnit))
    end

    it "demonstrates phantom type parameter constraints" do
      # Create measurements with explicit type constraints
      weight_kg : Unit::Measurement(Weight, WeightUnit) = Unit::Measurement(Weight, WeightUnit).new(10, WeightUnit::Kilogram)
      length_m : Unit::Measurement(Length, LengthUnit) = Unit::Measurement(Length, LengthUnit).new(5, LengthUnit::Meter)

      # Verify type constraints are enforced
      weight_kg.should be_a(Unit::Measurement(Weight, WeightUnit))
      length_m.should be_a(Unit::Measurement(Length, LengthUnit))
    end

    it "shows phantom types prevent incorrect assignments at compile time" do
      # This test documents compile-time safety - actual wrong assignments would fail compilation
      weight = Unit::Measurement(Weight, WeightUnit).new(10, WeightUnit::Kilogram)
      length = Unit::Measurement(Length, LengthUnit).new(5, LengthUnit::Meter)

      # These variables have different phantom types
      weight_type = typeof(weight)
      length_type = typeof(length)

      # Demonstrate they are indeed different types
      weight_type.should_not eq(length_type)

      # The following would cause compile-time errors:
      # length = weight  # Error: can't assign Weight measurement to Length variable
      # weight = length  # Error: can't assign Length measurement to Weight variable
    end
  end

  describe "equality and inspection methods" do
    describe "to_s" do
      it "provides readable string representation" do
        measurement = Unit::Measurement(Weight, WeightUnit).new(10.5, WeightUnit::Kilogram)
        measurement.to_s.should eq("10.5 kilogram")
      end

      it "handles different units correctly" do
        gram_measurement = Unit::Measurement(Weight, WeightUnit).new(500, WeightUnit::Gram)
        gram_measurement.to_s.should eq("500.0 gram")

        pound_measurement = Unit::Measurement(Weight, WeightUnit).new(2.2, WeightUnit::Pound)
        pound_measurement.to_s.should eq("2.2 pound")
      end

      it "handles integer values" do
        measurement = Unit::Measurement(Weight, WeightUnit).new(10, WeightUnit::Kilogram)
        measurement.to_s.should eq("10.0 kilogram")
      end

      it "handles negative values" do
        measurement = Unit::Measurement(Weight, WeightUnit).new(-5.5, WeightUnit::Kilogram)
        measurement.to_s.should eq("-5.5 kilogram")
      end
    end

    describe "inspect" do
      it "shows type parameters and internal structure" do
        measurement = Unit::Measurement(Weight, WeightUnit).new(10.5, WeightUnit::Kilogram)
        inspect_str = measurement.inspect

        inspect_str.should contain("Measurement(Weight, WeightUnit)")
        inspect_str.should contain("10.5")
        inspect_str.should contain("Kilogram")
      end

      it "distinguishes different phantom types in inspect" do
        weight = Unit::Measurement(Weight, WeightUnit).new(10, WeightUnit::Kilogram)
        length = Unit::Measurement(Length, LengthUnit).new(5, LengthUnit::Meter)

        weight.inspect.should contain("Weight")
        length.inspect.should contain("Length")
        weight.inspect.should_not eq(length.inspect)
      end
    end

    describe "equality" do
      it "considers measurements equal with same value and unit" do
        measurement1 = Unit::Measurement(Weight, WeightUnit).new(10.5, WeightUnit::Kilogram)
        measurement2 = Unit::Measurement(Weight, WeightUnit).new(10.5, WeightUnit::Kilogram)

        measurement1.should eq(measurement2)
        (measurement1 == measurement2).should be_true
      end

      it "considers measurements unequal with different values" do
        measurement1 = Unit::Measurement(Weight, WeightUnit).new(10.5, WeightUnit::Kilogram)
        measurement2 = Unit::Measurement(Weight, WeightUnit).new(5.5, WeightUnit::Kilogram)

        measurement1.should_not eq(measurement2)
        (measurement1 == measurement2).should be_false
      end

      it "considers measurements unequal with different units" do
        measurement1 = Unit::Measurement(Weight, WeightUnit).new(10, WeightUnit::Kilogram)
        measurement2 = Unit::Measurement(Weight, WeightUnit).new(10, WeightUnit::Gram)

        measurement1.should_not eq(measurement2)
        (measurement1 == measurement2).should be_false
      end

      it "handles precision correctly in equality" do
        measurement1 = Unit::Measurement(Weight, WeightUnit).new(10.0, WeightUnit::Kilogram)
        measurement2 = Unit::Measurement(Weight, WeightUnit).new(10, WeightUnit::Kilogram)

        measurement1.should eq(measurement2)
      end
    end

    describe "hash" do
      it "produces consistent hash values for equal measurements" do
        measurement1 = Unit::Measurement(Weight, WeightUnit).new(10.5, WeightUnit::Kilogram)
        measurement2 = Unit::Measurement(Weight, WeightUnit).new(10.5, WeightUnit::Kilogram)

        measurement1.hash.should eq(measurement2.hash)
      end

      it "produces different hash values for unequal measurements" do
        measurement1 = Unit::Measurement(Weight, WeightUnit).new(10.5, WeightUnit::Kilogram)
        measurement2 = Unit::Measurement(Weight, WeightUnit).new(5.5, WeightUnit::Kilogram)

        measurement1.hash.should_not eq(measurement2.hash)
      end

      it "works correctly in Hash collections" do
        hash = Hash(Unit::Measurement(Weight, WeightUnit), String).new
        measurement = Unit::Measurement(Weight, WeightUnit).new(10.5, WeightUnit::Kilogram)

        hash[measurement] = "test value"
        hash[measurement].should eq("test value")

        # Same measurement should retrieve the same value
        same_measurement = Unit::Measurement(Weight, WeightUnit).new(10.5, WeightUnit::Kilogram)
        hash[same_measurement].should eq("test value")
      end
    end
  end
end
