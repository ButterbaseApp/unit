require "../spec_helper"
require "../../src/unit/measurements/weight"
require "../../src/unit/measurements/length"
require "../../src/unit/measurements/volume"

describe Unit::Conversion do
  describe "Weight conversions" do
    describe "#convert_to" do
      it "converts kilograms to grams" do
        weight = Unit::Weight.new(2.5, Unit::Weight::Unit::Kilogram)
        converted = weight.convert_to(Unit::Weight::Unit::Gram)
        
        converted.value.should eq BigDecimal.new("2500.0")
        converted.unit.should eq Unit::Weight::Unit::Gram
      end
      
      it "converts grams to kilograms" do
        weight = Unit::Weight.new(2500, Unit::Weight::Unit::Gram)
        converted = weight.convert_to(Unit::Weight::Unit::Kilogram)
        
        converted.value.should eq BigDecimal.new("2.5")
        converted.unit.should eq Unit::Weight::Unit::Kilogram
      end
      
      it "converts pounds to grams" do
        weight = Unit::Weight.new(2, Unit::Weight::Unit::Pound)
        converted = weight.convert_to(Unit::Weight::Unit::Gram)
        
        # 2 pounds = 2 * 453.59237 = 907.18474 grams
        converted.value.should eq BigDecimal.new("907.18474")
        converted.unit.should eq Unit::Weight::Unit::Gram
      end
      
      it "converts ounces to pounds" do
        weight = Unit::Weight.new(16, Unit::Weight::Unit::Ounce)
        converted = weight.convert_to(Unit::Weight::Unit::Pound)
        
        # 16 ounces = 1 pound (exact conversion)
        converted.value.should eq BigDecimal.new("1.0")
        converted.unit.should eq Unit::Weight::Unit::Pound
      end
      
      it "returns self when converting to same unit" do
        weight = Unit::Weight.new(100, Unit::Weight::Unit::Gram)
        converted = weight.convert_to(Unit::Weight::Unit::Gram)
        
        converted.should be weight  # Same object reference
      end
    end
    
    describe "#to" do
      it "works as alias for convert_to" do
        weight = Unit::Weight.new(1, Unit::Weight::Unit::Kilogram)
        converted_to = weight.convert_to(Unit::Weight::Unit::Gram)
        to_result = weight.to(Unit::Weight::Unit::Gram)
        
        converted_to.value.should eq to_result.value
        converted_to.unit.should eq to_result.unit
      end
    end
    
    describe "round-trip conversions" do
      it "maintains precision for metric conversions" do
        original = Unit::Weight.new(2.5, Unit::Weight::Unit::Kilogram)
        converted = original.convert_to(Unit::Weight::Unit::Gram).convert_to(Unit::Weight::Unit::Kilogram)
        
        converted.value.should eq original.value
        converted.unit.should eq original.unit
      end
      
      it "maintains precision for imperial conversions" do
        original = Unit::Weight.new(2, Unit::Weight::Unit::Pound)
        converted = original.convert_to(Unit::Weight::Unit::Ounce).convert_to(Unit::Weight::Unit::Pound)
        
        converted.value.should eq original.value
        converted.unit.should eq original.unit
      end
    end
  end
  
  describe "Length conversions" do
    describe "#convert_to" do
      it "converts meters to centimeters" do
        length = Unit::Length.new(2.5, Unit::Length::Unit::Meter)
        converted = length.convert_to(Unit::Length::Unit::Centimeter)
        
        converted.value.should eq BigDecimal.new("250.0")
        converted.unit.should eq Unit::Length::Unit::Centimeter
      end
      
      it "converts feet to inches" do
        length = Unit::Length.new(2, Unit::Length::Unit::Foot)
        converted = length.convert_to(Unit::Length::Unit::Inch)
        
        # 2 feet = 24 inches (exact conversion)
        converted.value.should eq BigDecimal.new("24.0")
        converted.unit.should eq Unit::Length::Unit::Inch
      end
      
      it "converts meters to feet" do
        length = Unit::Length.new(1, Unit::Length::Unit::Meter)
        converted = length.convert_to(Unit::Length::Unit::Foot)
        
        # 1 meter = 1 / 0.3048 = 3.280839895... feet
        expected = BigDecimal.new("1") / BigDecimal.new("0.3048")
        converted.value.should eq expected
        converted.unit.should eq Unit::Length::Unit::Foot
      end
      
      it "converts kilometers to miles" do
        length = Unit::Length.new(1, Unit::Length::Unit::Kilometer)
        converted = length.convert_to(Unit::Length::Unit::Mile)
        
        # 1 km = 1000m, 1 mile = 1609.344m
        # 1 km = 1000 / 1609.344 miles ≈ 0.621371192 miles
        expected = BigDecimal.new("1000") / BigDecimal.new("1609.344")
        converted.value.should eq expected
        converted.unit.should eq Unit::Length::Unit::Mile
      end
    end
    
    describe "round-trip conversions" do
      it "maintains precision for metric conversions" do
        original = Unit::Length.new(1.5, Unit::Length::Unit::Meter)
        converted = original.convert_to(Unit::Length::Unit::Millimeter).convert_to(Unit::Length::Unit::Meter)
        
        converted.value.should eq original.value
        converted.unit.should eq original.unit
      end
      
      it "maintains precision for imperial conversions" do
        original = Unit::Length.new(3, Unit::Length::Unit::Yard)
        converted = original.convert_to(Unit::Length::Unit::Foot).convert_to(Unit::Length::Unit::Yard)
        
        converted.value.should eq original.value
        converted.unit.should eq original.unit
      end
    end
  end
  
  describe "Volume conversions" do
    describe "#convert_to" do
      it "converts liters to milliliters" do
        volume = Unit::Volume.new(2.5, Unit::Volume::Unit::Liter)
        converted = volume.convert_to(Unit::Volume::Unit::Milliliter)
        
        converted.value.should eq BigDecimal.new("2500.0")
        converted.unit.should eq Unit::Volume::Unit::Milliliter
      end
      
      it "converts gallons to quarts" do
        volume = Unit::Volume.new(2, Unit::Volume::Unit::Gallon)
        converted = volume.convert_to(Unit::Volume::Unit::Quart)
        
        # 2 gallons = 8 quarts (exact conversion)
        converted.value.should eq BigDecimal.new("8.0")
        converted.unit.should eq Unit::Volume::Unit::Quart
      end
      
      it "converts cups to fluid ounces" do
        volume = Unit::Volume.new(2, Unit::Volume::Unit::Cup)
        converted = volume.convert_to(Unit::Volume::Unit::FluidOunce)
        
        # 2 cups = 16 fluid ounces (exact conversion)
        converted.value.should eq BigDecimal.new("16.0")
        converted.unit.should eq Unit::Volume::Unit::FluidOunce
      end
      
      it "converts liters to gallons" do
        volume = Unit::Volume.new(1, Unit::Volume::Unit::Liter)
        converted = volume.convert_to(Unit::Volume::Unit::Gallon)
        
        # 1 liter = 1 / 3.785411784 gallons ≈ 0.264172052 gallons
        expected = BigDecimal.new("1") / BigDecimal.new("3.785411784")
        converted.value.should eq expected
        converted.unit.should eq Unit::Volume::Unit::Gallon
      end
    end
    
    describe "cooking conversions" do
      it "converts recipe measurements accurately" do
        # Common cooking conversion: 1 cup = 8 fluid ounces
        volume = Unit::Volume.new(1, Unit::Volume::Unit::Cup)
        converted = volume.convert_to(Unit::Volume::Unit::FluidOunce)
        
        converted.value.should eq BigDecimal.new("8.0")
        converted.unit.should eq Unit::Volume::Unit::FluidOunce
      end
      
      it "handles fractional cup measurements" do
        # 1/4 cup to fluid ounces
        volume = Unit::Volume.new(0.25, Unit::Volume::Unit::Cup)
        converted = volume.convert_to(Unit::Volume::Unit::FluidOunce)
        
        converted.value.should eq BigDecimal.new("2.0")
        converted.unit.should eq Unit::Volume::Unit::FluidOunce
      end
    end
    
    describe "round-trip conversions" do
      it "maintains precision for US liquid conversions" do
        original = Unit::Volume.new(1, Unit::Volume::Unit::Gallon)
        converted = original.convert_to(Unit::Volume::Unit::FluidOunce).convert_to(Unit::Volume::Unit::Gallon)
        
        converted.value.should eq original.value
        converted.unit.should eq original.unit
      end
      
      it "maintains precision for metric conversions" do
        original = Unit::Volume.new(2.5, Unit::Volume::Unit::Liter)
        converted = original.convert_to(Unit::Volume::Unit::Milliliter).convert_to(Unit::Volume::Unit::Liter)
        
        converted.value.should eq original.value
        converted.unit.should eq original.unit
      end
    end
  end
  
  describe "edge cases and precision" do
    it "handles very large numbers" do
      weight = Unit::Weight.new(1000000, Unit::Weight::Unit::Kilogram)
      converted = weight.convert_to(Unit::Weight::Unit::Gram)
      
      converted.value.should eq BigDecimal.new("1000000000.0")
      converted.unit.should eq Unit::Weight::Unit::Gram
    end
    
    it "handles very small numbers" do
      weight = Unit::Weight.new(0.001, Unit::Weight::Unit::Gram)
      converted = weight.convert_to(Unit::Weight::Unit::Milligram)
      
      converted.value.should eq BigDecimal.new("1.0")
      converted.unit.should eq Unit::Weight::Unit::Milligram
    end
    
    it "maintains BigDecimal precision throughout conversions" do
      # Test with a value that would lose precision in floating point
      length = Unit::Length.new(BigDecimal.new("1.123456789012345"), Unit::Length::Unit::Meter)
      converted = length.convert_to(Unit::Length::Unit::Millimeter)
      
      expected = BigDecimal.new("1123.456789012345")
      converted.value.should eq expected
    end
  end
  
  describe "conversion chain" do
    it "allows chaining multiple conversions" do
      # Start with 1 kilogram, convert to grams, then to pounds, then to ounces
      weight = Unit::Weight.new(1, Unit::Weight::Unit::Kilogram)
      final = weight
        .convert_to(Unit::Weight::Unit::Gram)
        .convert_to(Unit::Weight::Unit::Pound)
        .convert_to(Unit::Weight::Unit::Ounce)
      
      # 1 kg = 1000g = 1000/453.59237 lbs = (1000/453.59237) * 16 oz ≈ 35.274 oz
      expected_oz = (BigDecimal.new("1000") / BigDecimal.new("453.59237")) * BigDecimal.new("16")
      final.value.should eq expected_oz
      final.unit.should eq Unit::Weight::Unit::Ounce
    end
  end
end