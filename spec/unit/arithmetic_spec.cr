require "../spec_helper"
require "../../src/unit/measurements/weight"
require "../../src/unit/measurements/length"
require "../../src/unit/measurements/volume"

describe Unit::Arithmetic do
  describe "addition operations" do
    context "with same units" do
      it "adds weights with same unit" do
        weight1 = Unit::Weight.new(5, Unit::Weight::Unit::Kilogram)
        weight2 = Unit::Weight.new(3, Unit::Weight::Unit::Kilogram)
        result = weight1 + weight2

        result.value.should eq BigDecimal.new("8")
        result.unit.should eq Unit::Weight::Unit::Kilogram
      end

      it "adds lengths with same unit" do
        length1 = Unit::Length.new(100, Unit::Length::Unit::Centimeter)
        length2 = Unit::Length.new(50, Unit::Length::Unit::Centimeter)
        result = length1 + length2

        result.value.should eq BigDecimal.new("150")
        result.unit.should eq Unit::Length::Unit::Centimeter
      end
    end

    context "with different units" do
      it "adds weights with different units, preserving left operand unit" do
        weight_kg = Unit::Weight.new(1, Unit::Weight::Unit::Kilogram)
        weight_g = Unit::Weight.new(500, Unit::Weight::Unit::Gram)
        result = weight_kg + weight_g

        result.value.should eq BigDecimal.new("1.5")
        result.unit.should eq Unit::Weight::Unit::Kilogram
      end

      it "adds lengths with different units, preserving left operand unit" do
        length_cm = Unit::Length.new(100, Unit::Length::Unit::Centimeter)
        length_m = Unit::Length.new(1, Unit::Length::Unit::Meter)
        result = length_cm + length_m

        result.value.should eq BigDecimal.new("200")
        result.unit.should eq Unit::Length::Unit::Centimeter
      end
    end

    it "maintains immutability of original objects" do
      original = Unit::Weight.new(5, Unit::Weight::Unit::Kilogram)
      other = Unit::Weight.new(3, Unit::Weight::Unit::Kilogram)
      original_value = original.value
      other_value = other.value

      result = original + other

      original.value.should eq original_value
      other.value.should eq other_value
      result.value.should eq BigDecimal.new("8")
    end
  end

  describe "subtraction operations" do
    context "with same units" do
      it "subtracts weights with same unit" do
        weight1 = Unit::Weight.new(5, Unit::Weight::Unit::Kilogram)
        weight2 = Unit::Weight.new(3, Unit::Weight::Unit::Kilogram)
        result = weight1 - weight2

        result.value.should eq BigDecimal.new("2")
        result.unit.should eq Unit::Weight::Unit::Kilogram
      end
    end

    context "with different units" do
      it "subtracts weights with different units, preserving left operand unit" do
        weight_kg = Unit::Weight.new(2, Unit::Weight::Unit::Kilogram)
        weight_g = Unit::Weight.new(500, Unit::Weight::Unit::Gram)
        result = weight_kg - weight_g

        result.value.should eq BigDecimal.new("1.5")
        result.unit.should eq Unit::Weight::Unit::Kilogram
      end
    end

    it "handles negative results correctly" do
      weight1 = Unit::Weight.new(3, Unit::Weight::Unit::Kilogram)
      weight2 = Unit::Weight.new(5, Unit::Weight::Unit::Kilogram)
      result = weight1 - weight2

      result.value.should eq BigDecimal.new("-2")
      result.unit.should eq Unit::Weight::Unit::Kilogram
    end

    it "maintains immutability of original objects" do
      original = Unit::Weight.new(5, Unit::Weight::Unit::Kilogram)
      other = Unit::Weight.new(3, Unit::Weight::Unit::Kilogram)
      original_value = original.value
      other_value = other.value

      result = original - other
      result.should eq(Unit::Weight.new(2, Unit::Weight::Unit::Kilogram))

      original.value.should eq original_value
      other.value.should eq other_value
    end
  end

  describe "scalar multiplication" do
    it "multiplies weight by integer" do
      weight = Unit::Weight.new(5, Unit::Weight::Unit::Kilogram)
      result = weight * 2

      result.value.should eq BigDecimal.new("10")
      result.unit.should eq Unit::Weight::Unit::Kilogram
    end

    it "multiplies weight by float" do
      weight = Unit::Weight.new(5, Unit::Weight::Unit::Kilogram)
      result = weight * 1.5

      result.value.should eq BigDecimal.new("7.5")
      result.unit.should eq Unit::Weight::Unit::Kilogram
    end

    it "multiplies length by decimal" do
      length = Unit::Length.new(10, Unit::Length::Unit::Meter)
      result = length * 2.5

      result.value.should eq BigDecimal.new("25")
      result.unit.should eq Unit::Length::Unit::Meter
    end

    it "preserves precision with BigDecimal arithmetic" do
      weight = Unit::Weight.new(1.23456789, Unit::Weight::Unit::Kilogram)
      result = weight * 3

      result.value.should eq BigDecimal.new("3.70370367")
      result.unit.should eq Unit::Weight::Unit::Kilogram
    end

    it "maintains immutability" do
      original = Unit::Weight.new(5, Unit::Weight::Unit::Kilogram)
      original_value = original.value

      result = original * 2

      original.value.should eq original_value
      result.value.should eq BigDecimal.new("10")
    end
  end

  describe "scalar division" do
    it "divides weight by integer" do
      weight = Unit::Weight.new(10, Unit::Weight::Unit::Kilogram)
      result = weight / 2

      result.value.should eq BigDecimal.new("5")
      result.unit.should eq Unit::Weight::Unit::Kilogram
    end

    it "divides weight by float" do
      weight = Unit::Weight.new(10, Unit::Weight::Unit::Kilogram)
      result = weight / 2.5

      result.value.should eq BigDecimal.new("4")
      result.unit.should eq Unit::Weight::Unit::Kilogram
    end

    it "handles decimal results" do
      weight = Unit::Weight.new(5, Unit::Weight::Unit::Kilogram)
      result = weight / 3

      # BigDecimal division with default precision
      result.value.to_s.should match(/1\.66666666.*/)
      result.unit.should eq Unit::Weight::Unit::Kilogram
    end

    it "raises ArgumentError for division by zero" do
      weight = Unit::Weight.new(5, Unit::Weight::Unit::Kilogram)

      expect_raises(ArgumentError, "Cannot divide by zero") do
        weight / 0
      end
    end

    it "maintains immutability" do
      original = Unit::Weight.new(10, Unit::Weight::Unit::Kilogram)
      original_value = original.value

      result = original / 2

      original.value.should eq original_value
      result.value.should eq BigDecimal.new("5")
    end
  end

  describe "chained operations" do
    it "handles complex arithmetic expressions" do
      weight1 = Unit::Weight.new(10, Unit::Weight::Unit::Kilogram)
      weight2 = Unit::Weight.new(5, Unit::Weight::Unit::Kilogram)
      weight3 = Unit::Weight.new(2, Unit::Weight::Unit::Kilogram)

      # (10 + 5) * 2 - 3
      result = ((weight1 + weight2) * 2) - weight3

      result.value.should eq BigDecimal.new("28")
      result.unit.should eq Unit::Weight::Unit::Kilogram
    end

    it "handles mixed unit operations" do
      weight_kg = Unit::Weight.new(1, Unit::Weight::Unit::Kilogram)
      weight_g = Unit::Weight.new(500, Unit::Weight::Unit::Gram)

      # 1kg + 500g = 1.5kg, then * 2 = 3kg, then - 500g = 2.5kg
      result = ((weight_kg + weight_g) * 2) - weight_g

      result.value.should eq BigDecimal.new("2.5")
      result.unit.should eq Unit::Weight::Unit::Kilogram
    end
  end

  describe "type safety" do
    it "ensures operations only work on same measurement types" do
      # This test verifies compile-time type safety
      # Different measurement types (Weight vs Length) cannot be added
      weight = Unit::Weight.new(5, Unit::Weight::Unit::Kilogram)
      length = Unit::Length.new(10, Unit::Length::Unit::Meter)

      # The following would not compile:
      # result = weight + length  # Compile error!

      # This is a runtime verification that the types are indeed different
      weight.class.should_not eq length.class
    end
  end
end
