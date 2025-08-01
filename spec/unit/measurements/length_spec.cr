require "../../spec_helper"
require "../../../src/unit/measurements/length"

describe Unit::Length do
  describe "initialization" do
    it "creates length with meter unit" do
      length = Unit::Length.new(100, Unit::Length::Unit::Meter)
      length.value.should eq BigDecimal.new("100")
      length.unit.should eq Unit::Length::Unit::Meter
    end
    
    it "creates length with foot unit" do
      length = Unit::Length.new(10.5, Unit::Length::Unit::Foot)
      length.value.should eq BigDecimal.new("10.5")
      length.unit.should eq Unit::Length::Unit::Foot
    end
    
    it "creates length with inch unit" do
      length = Unit::Length.new(12, Unit::Length::Unit::Inch)
      length.value.should eq BigDecimal.new("12")
      length.unit.should eq Unit::Length::Unit::Inch
    end
    
    it "handles various numeric types" do
      Unit::Length.new(10_i32, Unit::Length::Unit::Meter).value.should eq BigDecimal.new("10")
      Unit::Length.new(10_i64, Unit::Length::Unit::Meter).value.should eq BigDecimal.new("10")
      Unit::Length.new(10.5_f32, Unit::Length::Unit::Meter).value.should eq BigDecimal.new("10.5")
      Unit::Length.new(10.5_f64, Unit::Length::Unit::Meter).value.should eq BigDecimal.new("10.5")
    end
    
    it "rejects invalid float values" do
      expect_raises(ArgumentError, "Value cannot be NaN") do
        Unit::Length.new(Float64::NAN, Unit::Length::Unit::Meter)
      end
      
      expect_raises(ArgumentError, "Value cannot be infinite") do
        Unit::Length.new(Float64::INFINITY, Unit::Length::Unit::Meter)
      end
    end
  end
  
  describe "Unit enum" do
    it "has all expected units" do
      units = Unit::Length::Unit.values
      units.should contain Unit::Length::Unit::Meter
      units.should contain Unit::Length::Unit::Centimeter
      units.should contain Unit::Length::Unit::Millimeter
      units.should contain Unit::Length::Unit::Kilometer
      units.should contain Unit::Length::Unit::Inch
      units.should contain Unit::Length::Unit::Foot
      units.should contain Unit::Length::Unit::Yard
      units.should contain Unit::Length::Unit::Mile
    end
    
    it "supports unit aliases" do
      Unit::Length::Unit::M.should eq Unit::Length::Unit::Meter
      Unit::Length::Unit::Cm.should eq Unit::Length::Unit::Centimeter
      Unit::Length::Unit::Mm.should eq Unit::Length::Unit::Millimeter
      Unit::Length::Unit::Km.should eq Unit::Length::Unit::Kilometer
      Unit::Length::Unit::In.should eq Unit::Length::Unit::Inch
      Unit::Length::Unit::Ft.should eq Unit::Length::Unit::Foot
      Unit::Length::Unit::Yd.should eq Unit::Length::Unit::Yard
      Unit::Length::Unit::Mi.should eq Unit::Length::Unit::Mile
    end
    
    describe "#metric?" do
      it "identifies metric units correctly" do
        Unit::Length::Unit::Meter.metric?.should be_true
        Unit::Length::Unit::Centimeter.metric?.should be_true
        Unit::Length::Unit::Millimeter.metric?.should be_true
        Unit::Length::Unit::Kilometer.metric?.should be_true
        
        Unit::Length::Unit::Inch.metric?.should be_false
        Unit::Length::Unit::Foot.metric?.should be_false
        Unit::Length::Unit::Yard.metric?.should be_false
        Unit::Length::Unit::Mile.metric?.should be_false
      end
    end
    
    describe "#symbol" do
      it "returns correct symbols" do
        Unit::Length::Unit::Meter.symbol.should eq "m"
        Unit::Length::Unit::Centimeter.symbol.should eq "cm"
        Unit::Length::Unit::Millimeter.symbol.should eq "mm"
        Unit::Length::Unit::Kilometer.symbol.should eq "km"
        Unit::Length::Unit::Inch.symbol.should eq "in"
        Unit::Length::Unit::Foot.symbol.should eq "ft"
        Unit::Length::Unit::Yard.symbol.should eq "yd"
        Unit::Length::Unit::Mile.symbol.should eq "mi"
      end
    end
    
    describe "#name" do
      it "returns singular names" do
        Unit::Length::Unit::Meter.name.should eq "meter"
        Unit::Length::Unit::Centimeter.name.should eq "centimeter"
        Unit::Length::Unit::Foot.name.should eq "foot"
        Unit::Length::Unit::Inch.name.should eq "inch"
      end
      
      it "returns plural names when requested" do
        Unit::Length::Unit::Meter.name(plural: true).should eq "meters"
        Unit::Length::Unit::Centimeter.name(plural: true).should eq "centimeters"
        Unit::Length::Unit::Foot.name(plural: true).should eq "feet"
        Unit::Length::Unit::Inch.name(plural: true).should eq "inches"
      end
    end
  end
  
  describe "conversion factors" do
    it "has correct conversion factors based on international standards" do
      Unit::Length::CONVERSION_FACTORS[Unit::Length::Unit::Meter].should eq BigDecimal.new("1")
      Unit::Length::CONVERSION_FACTORS[Unit::Length::Unit::Centimeter].should eq BigDecimal.new("0.01")
      Unit::Length::CONVERSION_FACTORS[Unit::Length::Unit::Millimeter].should eq BigDecimal.new("0.001")
      Unit::Length::CONVERSION_FACTORS[Unit::Length::Unit::Kilometer].should eq BigDecimal.new("1000")
      Unit::Length::CONVERSION_FACTORS[Unit::Length::Unit::Inch].should eq BigDecimal.new("0.0254")
      Unit::Length::CONVERSION_FACTORS[Unit::Length::Unit::Foot].should eq BigDecimal.new("0.3048")
      Unit::Length::CONVERSION_FACTORS[Unit::Length::Unit::Yard].should eq BigDecimal.new("0.9144")
      Unit::Length::CONVERSION_FACTORS[Unit::Length::Unit::Mile].should eq BigDecimal.new("1609.344")
    end
    
    it "validates foot to inch relationship" do
      foot_factor = Unit::Length::CONVERSION_FACTORS[Unit::Length::Unit::Foot]
      inch_factor = Unit::Length::CONVERSION_FACTORS[Unit::Length::Unit::Inch]
      
      # 12 inches should equal 1 foot
      (inch_factor * BigDecimal.new("12")).should eq foot_factor
    end
    
    it "validates yard to foot relationship" do
      yard_factor = Unit::Length::CONVERSION_FACTORS[Unit::Length::Unit::Yard]
      foot_factor = Unit::Length::CONVERSION_FACTORS[Unit::Length::Unit::Foot]
      
      # 3 feet should equal 1 yard
      (foot_factor * BigDecimal.new("3")).should eq yard_factor
    end
    
    it "validates mile to foot relationship" do
      mile_factor = Unit::Length::CONVERSION_FACTORS[Unit::Length::Unit::Mile]
      foot_factor = Unit::Length::CONVERSION_FACTORS[Unit::Length::Unit::Foot]
      
      # 5280 feet should equal 1 mile
      (foot_factor * BigDecimal.new("5280")).should eq mile_factor
    end
    
    it "validates metric system relationships" do
      meter_factor = Unit::Length::CONVERSION_FACTORS[Unit::Length::Unit::Meter]
      cm_factor = Unit::Length::CONVERSION_FACTORS[Unit::Length::Unit::Centimeter]
      mm_factor = Unit::Length::CONVERSION_FACTORS[Unit::Length::Unit::Millimeter]
      km_factor = Unit::Length::CONVERSION_FACTORS[Unit::Length::Unit::Kilometer]
      
      # 100 cm should equal 1 meter
      (cm_factor * BigDecimal.new("100")).should eq meter_factor
      
      # 1000 mm should equal 1 meter
      (mm_factor * BigDecimal.new("1000")).should eq meter_factor
      
      # 1000 meters should equal 1 kilometer
      (meter_factor * BigDecimal.new("1000")).should eq km_factor
    end
  end
  
  describe "class methods" do
    describe ".base_unit" do
      it "returns meter as base unit" do
        Unit::Length.base_unit.should eq Unit::Length::Unit::Meter
      end
    end
    
    describe ".conversion_factor" do
      it "returns correct conversion factors" do
        Unit::Length.conversion_factor(Unit::Length::Unit::Kilometer).should eq BigDecimal.new("1000")
        Unit::Length.conversion_factor(Unit::Length::Unit::Foot).should eq BigDecimal.new("0.3048")
        Unit::Length.conversion_factor(Unit::Length::Unit::Inch).should eq BigDecimal.new("0.0254")
      end
    end
    
    describe ".metric_unit?" do
      it "identifies metric units correctly" do
        Unit::Length.metric_unit?(Unit::Length::Unit::Meter).should be_true
        Unit::Length.metric_unit?(Unit::Length::Unit::Centimeter).should be_true
        Unit::Length.metric_unit?(Unit::Length::Unit::Foot).should be_false
        Unit::Length.metric_unit?(Unit::Length::Unit::Inch).should be_false
      end
    end
  end
  
  describe "instance methods" do    
    describe "#symbol" do
      it "returns unit symbol" do
        length_m = Unit::Length.new(2.5, Unit::Length::Unit::Meter)
        length_ft = Unit::Length.new(5.5, Unit::Length::Unit::Foot)
        
        length_m.symbol.should eq "m"
        length_ft.symbol.should eq "ft"
      end
    end
    
    describe "#unit_name" do
      it "returns singular unit name" do
        length_m = Unit::Length.new(2.5, Unit::Length::Unit::Meter)
        length_ft = Unit::Length.new(5.5, Unit::Length::Unit::Foot)
        
        length_m.unit_name.should eq "meter"
        length_ft.unit_name.should eq "foot"
      end
      
      it "returns plural unit name when requested" do
        length_m = Unit::Length.new(2.5, Unit::Length::Unit::Meter)
        length_ft = Unit::Length.new(5.5, Unit::Length::Unit::Foot)
        
        length_m.unit_name(plural: true).should eq "meters"
        length_ft.unit_name(plural: true).should eq "feet"
      end
    end
  end
  
  describe "core functionality" do
    it "supports equality comparison" do
      length1 = Unit::Length.new(100, Unit::Length::Unit::Centimeter)
      length2 = Unit::Length.new(1, Unit::Length::Unit::Meter)
      length3 = Unit::Length.new(100, Unit::Length::Unit::Centimeter)
      
      length1.should_not eq length2  # Different units, even if equivalent
      length1.should eq length3      # Same value and unit
    end
    
    it "supports hash functionality" do
      length1 = Unit::Length.new(100, Unit::Length::Unit::Centimeter)
      length2 = Unit::Length.new(1, Unit::Length::Unit::Meter)
      length3 = Unit::Length.new(100, Unit::Length::Unit::Centimeter)
      
      length1.hash.should eq length3.hash
      length1.hash.should_not eq length2.hash
    end
    
    it "has string representation" do
      length1 = Unit::Length.new(100, Unit::Length::Unit::Centimeter)
      length2 = Unit::Length.new(1, Unit::Length::Unit::Meter)
      
      length1.to_s.should eq "100.0 centimeter"
      length2.to_s.should eq "1.0 meter"
    end
    
    it "has inspect functionality" do
      length1 = Unit::Length.new(100, Unit::Length::Unit::Centimeter)
      expected = "Length(100.0, Centimeter)"
      length1.inspect.should eq expected
    end
  end
  
  describe "type safety" do
    it "ensures type safety for length operations" do
      # This should compile - same types
      length1 = Unit::Length.new(100, Unit::Length::Unit::Centimeter)
      length2 = Unit::Length.new(200, Unit::Length::Unit::Centimeter)
      
      # These operations should be type-safe
      length1.should_not eq length2
      length1.value.should be < length2.value
    end
  end
  
  describe "precision validation" do
    it "maintains BigDecimal precision for all conversions" do
      # Test that exact conversion factors are preserved
      inch_factor = Unit::Length.conversion_factor(Unit::Length::Unit::Inch)
      foot_factor = Unit::Length.conversion_factor(Unit::Length::Unit::Foot)
      
      # The international inch is exactly 25.4 mm = 0.0254 m
      inch_factor.should eq BigDecimal.new("0.0254")
      
      # The international foot is exactly 0.3048 m  
      foot_factor.should eq BigDecimal.new("0.3048")
      
      # Verify that these are exact, not rounded
      inch_factor.to_s.should eq "0.0254"
      foot_factor.to_s.should eq "0.3048"
    end
  end
end