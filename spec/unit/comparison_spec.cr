require "../spec_helper"
require "../../src/unit/measurements/weight"
require "../../src/unit/measurements/length"
require "../../src/unit/measurements/volume"

describe Unit::Comparison do
  describe "spaceship operator (<=>) with unit conversion" do
    context "with same units" do
      it "compares weights correctly" do
        weight1 = Unit::Weight.new(5, Unit::Weight::Unit::Kilogram)
        weight2 = Unit::Weight.new(3, Unit::Weight::Unit::Kilogram)
        weight3 = Unit::Weight.new(5, Unit::Weight::Unit::Kilogram)

        (weight1 <=> weight2).should eq 1
        (weight2 <=> weight1).should eq -1
        (weight1 <=> weight3).should eq 0
      end

      it "compares lengths correctly" do
        length1 = Unit::Length.new(100, Unit::Length::Unit::Centimeter)
        length2 = Unit::Length.new(50, Unit::Length::Unit::Centimeter)

        (length1 <=> length2).should eq 1
        (length2 <=> length1).should eq -1
      end
    end

    context "with different units" do
      it "compares weights across units" do
        weight_kg = Unit::Weight.new(1, Unit::Weight::Unit::Kilogram)
        weight_g = Unit::Weight.new(1500, Unit::Weight::Unit::Gram)
        weight_g2 = Unit::Weight.new(500, Unit::Weight::Unit::Gram)

        (weight_kg <=> weight_g).should eq -1 # 1kg < 1.5kg
        (weight_kg <=> weight_g2).should eq 1 # 1kg > 0.5kg
      end

      it "compares lengths across units" do
        length_m = Unit::Length.new(1, Unit::Length::Unit::Meter)
        length_cm = Unit::Length.new(150, Unit::Length::Unit::Centimeter)
        length_cm2 = Unit::Length.new(50, Unit::Length::Unit::Centimeter)

        (length_m <=> length_cm).should eq -1 # 1m < 1.5m
        (length_m <=> length_cm2).should eq 1 # 1m > 0.5m
      end
    end
  end

  describe "Comparable module methods" do
    context "ordering methods" do
      it "provides < > <= >= operators" do
        weight1 = Unit::Weight.new(1, Unit::Weight::Unit::Kilogram)
        weight2 = Unit::Weight.new(500, Unit::Weight::Unit::Gram)
        weight3 = Unit::Weight.new(1500, Unit::Weight::Unit::Gram)

        (weight1 > weight2).should be_true
        (weight1 < weight3).should be_true
        (weight1 >= weight2).should be_true
        (weight1 <= weight3).should be_true
        (weight1 >= weight1).should be_true
        (weight1 <= weight1).should be_true
      end

      it "enables sorting and range operations" do
        weight_low = Unit::Weight.new(500, Unit::Weight::Unit::Gram)
        weight_mid = Unit::Weight.new(1, Unit::Weight::Unit::Kilogram)
        weight_high = Unit::Weight.new(1500, Unit::Weight::Unit::Gram)

        # Test sorting works
        [weight_high, weight_low, weight_mid].sort.should eq [weight_low, weight_mid, weight_high]

        # Test range operations
        (weight_low < weight_mid < weight_high).should be_true
      end
    end
  end

  describe "equality with unit conversion" do
    context "equivalent measurements" do
      it "considers equivalent weights equal" do
        weight1 = Unit::Weight.new(1, Unit::Weight::Unit::Kilogram)
        weight2 = Unit::Weight.new(1000, Unit::Weight::Unit::Gram)

        (weight1 == weight2).should be_true
        (weight2 == weight1).should be_true
      end

      it "considers equivalent lengths equal" do
        length1 = Unit::Length.new(1, Unit::Length::Unit::Meter)
        length2 = Unit::Length.new(100, Unit::Length::Unit::Centimeter)

        (length1 == length2).should be_true
        (length2 == length1).should be_true
      end

      it "considers equivalent volumes equal" do
        volume1 = Unit::Volume.new(1, Unit::Volume::Unit::Liter)
        volume2 = Unit::Volume.new(1000, Unit::Volume::Unit::Milliliter)

        (volume1 == volume2).should be_true
        (volume2 == volume1).should be_true
      end
    end

    context "non-equivalent measurements" do
      it "considers different weights unequal" do
        weight1 = Unit::Weight.new(1, Unit::Weight::Unit::Kilogram)
        weight2 = Unit::Weight.new(500, Unit::Weight::Unit::Gram)

        (weight1 == weight2).should be_false
        (weight2 == weight1).should be_false
      end
    end

    it "handles precision correctly with converted values" do
      # Test with values that require precision handling
      weight1 = Unit::Weight.new(2.20462, Unit::Weight::Unit::Pound)
      weight2 = Unit::Weight.new(1, Unit::Weight::Unit::Kilogram)

      # These should be approximately equal (2.20462 lb ≈ 1 kg)
      # but may not be exactly equal due to conversion precision
      (weight1 == weight2).should be_false # Slight precision difference expected

      # But they should be very close
      diff = (weight1.convert_to(Unit::Weight::Unit::Gram).value -
              weight2.convert_to(Unit::Weight::Unit::Gram).value).abs
      diff.should be < BigDecimal.new("0.1")
    end
  end

  describe "hash consistency" do
    it "produces equal hashes for equivalent measurements" do
      weight1 = Unit::Weight.new(1, Unit::Weight::Unit::Kilogram)
      weight2 = Unit::Weight.new(1000, Unit::Weight::Unit::Gram)

      weight1.hash.should eq weight2.hash
    end

    it "produces different hashes for different measurements" do
      weight1 = Unit::Weight.new(1, Unit::Weight::Unit::Kilogram)
      weight2 = Unit::Weight.new(500, Unit::Weight::Unit::Gram)

      weight1.hash.should_not eq weight2.hash
    end

    it "works correctly with Hash collections" do
      weight_kg = Unit::Weight.new(1, Unit::Weight::Unit::Kilogram)
      weight_g = Unit::Weight.new(1000, Unit::Weight::Unit::Gram)

      hash = {} of Unit::Weight => String
      hash[weight_kg] = "one kilogram"

      # Should be able to access with equivalent measurement
      hash[weight_g].should eq "one kilogram"
    end

    it "works correctly with Set collections" do
      weight1 = Unit::Weight.new(1, Unit::Weight::Unit::Kilogram)
      weight2 = Unit::Weight.new(1000, Unit::Weight::Unit::Gram)
      weight3 = Unit::Weight.new(500, Unit::Weight::Unit::Gram)

      set = Set{weight1, weight2, weight3}

      # Should only have 2 unique items (weight1 == weight2)
      set.size.should eq 2
      set.should contain weight1
      set.should contain weight3

      # Both representations should work for checking membership
      set.includes?(weight1).should be_true
      set.includes?(weight2).should be_true # Same as weight1
    end
  end

  describe "sorting arrays" do
    it "sorts mixed-unit weights correctly" do
      weights = [
        Unit::Weight.new(2, Unit::Weight::Unit::Kilogram),   # 2000g
        Unit::Weight.new(500, Unit::Weight::Unit::Gram),     # 500g
        Unit::Weight.new(1.5, Unit::Weight::Unit::Kilogram), # 1500g
        Unit::Weight.new(3000, Unit::Weight::Unit::Gram),    # 3000g
        Unit::Weight.new(1, Unit::Weight::Unit::Kilogram),   # 1000g
      ]

      sorted = weights.sort

      # Expected order: 500g, 1kg, 1.5kg, 2kg, 3kg
      sorted[0].should eq Unit::Weight.new(500, Unit::Weight::Unit::Gram)
      sorted[1].should eq Unit::Weight.new(1, Unit::Weight::Unit::Kilogram)
      sorted[2].should eq Unit::Weight.new(1.5, Unit::Weight::Unit::Kilogram)
      sorted[3].should eq Unit::Weight.new(2, Unit::Weight::Unit::Kilogram)
      sorted[4].should eq Unit::Weight.new(3000, Unit::Weight::Unit::Gram)
    end

    it "sorts mixed-unit lengths correctly" do
      lengths = [
        Unit::Length.new(2, Unit::Length::Unit::Meter),        # 200cm
        Unit::Length.new(50, Unit::Length::Unit::Centimeter),  # 50cm
        Unit::Length.new(1.5, Unit::Length::Unit::Meter),      # 150cm
        Unit::Length.new(300, Unit::Length::Unit::Centimeter), # 300cm
      ]

      sorted = lengths.sort

      # Expected order: 50cm, 150cm, 200cm, 300cm
      sorted[0].should eq Unit::Length.new(50, Unit::Length::Unit::Centimeter)
      sorted[1].should eq Unit::Length.new(1.5, Unit::Length::Unit::Meter)
      sorted[2].should eq Unit::Length.new(2, Unit::Length::Unit::Meter)
      sorted[3].should eq Unit::Length.new(300, Unit::Length::Unit::Centimeter)
    end
  end

  describe "edge cases" do
    it "handles zero values correctly" do
      weight1 = Unit::Weight.new(0, Unit::Weight::Unit::Kilogram)
      weight2 = Unit::Weight.new(0, Unit::Weight::Unit::Gram)

      (weight1 == weight2).should be_true
      (weight1 <=> weight2).should eq 0
      weight1.hash.should eq weight2.hash
    end

    it "handles negative values correctly" do
      weight1 = Unit::Weight.new(-1, Unit::Weight::Unit::Kilogram)
      weight2 = Unit::Weight.new(-500, Unit::Weight::Unit::Gram)

      (weight1 < weight2).should be_true # -1000g < -500g
      (weight1 == weight2).should be_false
    end

    it "handles very large numbers" do
      weight1 = Unit::Weight.new(1000000, Unit::Weight::Unit::Kilogram)
      weight2 = Unit::Weight.new(1000000000, Unit::Weight::Unit::Gram)

      (weight1 == weight2).should be_true
      weight1.hash.should eq weight2.hash
    end

    it "handles very small numbers" do
      weight1 = Unit::Weight.new(0.001, Unit::Weight::Unit::Kilogram)
      weight2 = Unit::Weight.new(1, Unit::Weight::Unit::Gram)

      (weight1 == weight2).should be_true
      weight1.hash.should eq weight2.hash
    end
  end
end
