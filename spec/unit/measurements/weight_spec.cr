require "../../spec_helper"
require "../../../src/unit/measurements/weight"

describe Unit::Weight do
  describe "initialization" do
    it "creates weight with gram unit" do
      weight = Unit::Weight.new(100, Unit::Weight::Unit::Gram)
      weight.value.should eq BigDecimal.new("100")
      weight.unit.should eq Unit::Weight::Unit::Gram
    end
    
    it "creates weight with kilogram unit" do
      weight = Unit::Weight.new(2.5, Unit::Weight::Unit::Kilogram)
      weight.value.should eq BigDecimal.new("2.5")
      weight.unit.should eq Unit::Weight::Unit::Kilogram
    end
    
    it "creates weight with pound unit" do
      weight = Unit::Weight.new(10, Unit::Weight::Unit::Pound)
      weight.value.should eq BigDecimal.new("10")
      weight.unit.should eq Unit::Weight::Unit::Pound
    end
    
    it "handles various numeric types" do
      Unit::Weight.new(10_i32, Unit::Weight::Unit::Gram).value.should eq BigDecimal.new("10")
      Unit::Weight.new(10_i64, Unit::Weight::Unit::Gram).value.should eq BigDecimal.new("10")
      Unit::Weight.new(10.5_f32, Unit::Weight::Unit::Gram).value.should eq BigDecimal.new("10.5")
      Unit::Weight.new(10.5_f64, Unit::Weight::Unit::Gram).value.should eq BigDecimal.new("10.5")
    end
    
    it "rejects invalid float values" do
      expect_raises(ArgumentError, "Value cannot be NaN") do
        Unit::Weight.new(Float64::NAN, Unit::Weight::Unit::Gram)
      end
      
      expect_raises(ArgumentError, "Value cannot be infinite") do
        Unit::Weight.new(Float64::INFINITY, Unit::Weight::Unit::Gram)
      end
    end
  end
  
  describe "Unit enum" do
    it "has all expected units" do
      units = Unit::Weight::Unit.values
      units.should contain Unit::Weight::Unit::Gram
      units.should contain Unit::Weight::Unit::Kilogram
      units.should contain Unit::Weight::Unit::Milligram
      units.should contain Unit::Weight::Unit::Tonne
      units.should contain Unit::Weight::Unit::Pound
      units.should contain Unit::Weight::Unit::Ounce
      units.should contain Unit::Weight::Unit::Slug
    end
    
    it "supports unit aliases" do
      Unit::Weight::Unit::G.should eq Unit::Weight::Unit::Gram
      Unit::Weight::Unit::Kg.should eq Unit::Weight::Unit::Kilogram
      Unit::Weight::Unit::Mg.should eq Unit::Weight::Unit::Milligram
      Unit::Weight::Unit::T.should eq Unit::Weight::Unit::Tonne
      Unit::Weight::Unit::Lb.should eq Unit::Weight::Unit::Pound
      Unit::Weight::Unit::Oz.should eq Unit::Weight::Unit::Ounce
    end
    
    describe "#metric?" do
      it "identifies metric units correctly" do
        Unit::Weight::Unit::Gram.metric?.should be_true
        Unit::Weight::Unit::Kilogram.metric?.should be_true
        Unit::Weight::Unit::Milligram.metric?.should be_true
        Unit::Weight::Unit::Tonne.metric?.should be_true
        
        Unit::Weight::Unit::Pound.metric?.should be_false
        Unit::Weight::Unit::Ounce.metric?.should be_false
        Unit::Weight::Unit::Slug.metric?.should be_false
      end
    end
    
    describe "#symbol" do
      it "returns correct symbols" do
        Unit::Weight::Unit::Gram.symbol.should eq "g"
        Unit::Weight::Unit::Kilogram.symbol.should eq "kg"
        Unit::Weight::Unit::Milligram.symbol.should eq "mg"
        Unit::Weight::Unit::Tonne.symbol.should eq "t"
        Unit::Weight::Unit::Pound.symbol.should eq "lb"
        Unit::Weight::Unit::Ounce.symbol.should eq "oz"
        Unit::Weight::Unit::Slug.symbol.should eq "slug"
      end
    end
    
    describe "#name" do
      it "returns singular names" do
        Unit::Weight::Unit::Gram.name.should eq "gram"
        Unit::Weight::Unit::Kilogram.name.should eq "kilogram"
        Unit::Weight::Unit::Pound.name.should eq "pound"
        Unit::Weight::Unit::Ounce.name.should eq "ounce"
      end
      
      it "returns plural names when requested" do
        Unit::Weight::Unit::Gram.name(plural: true).should eq "grams"
        Unit::Weight::Unit::Kilogram.name(plural: true).should eq "kilograms"
        Unit::Weight::Unit::Pound.name(plural: true).should eq "pounds"
        Unit::Weight::Unit::Ounce.name(plural: true).should eq "ounces"
      end
    end
  end
  
  describe "conversion factors" do
    it "has correct conversion factors" do
      Unit::Weight::CONVERSION_FACTORS[Unit::Weight::Unit::Gram].should eq BigDecimal.new("1")
      Unit::Weight::CONVERSION_FACTORS[Unit::Weight::Unit::Kilogram].should eq BigDecimal.new("1000")
      Unit::Weight::CONVERSION_FACTORS[Unit::Weight::Unit::Milligram].should eq BigDecimal.new("0.001")
      Unit::Weight::CONVERSION_FACTORS[Unit::Weight::Unit::Tonne].should eq BigDecimal.new("1000000")
      Unit::Weight::CONVERSION_FACTORS[Unit::Weight::Unit::Pound].should eq BigDecimal.new("453.59237")
      Unit::Weight::CONVERSION_FACTORS[Unit::Weight::Unit::Ounce].should eq BigDecimal.new("28.349523125")
      Unit::Weight::CONVERSION_FACTORS[Unit::Weight::Unit::Slug].should eq BigDecimal.new("14593.903")
    end
    
    it "validates ounce to pound relationship" do
      ounce_factor = Unit::Weight::CONVERSION_FACTORS[Unit::Weight::Unit::Ounce]
      pound_factor = Unit::Weight::CONVERSION_FACTORS[Unit::Weight::Unit::Pound]
      
      # 16 ounces should equal 1 pound
      (ounce_factor * BigDecimal.new("16")).should eq pound_factor
    end
  end
  
  describe "class methods" do
    describe ".base_unit" do
      it "returns gram as base unit" do
        Unit::Weight.base_unit.should eq Unit::Weight::Unit::Gram
      end
    end
    
    describe ".conversion_factor" do
      it "returns correct conversion factors" do
        Unit::Weight.conversion_factor(Unit::Weight::Unit::Kilogram).should eq BigDecimal.new("1000")
        Unit::Weight.conversion_factor(Unit::Weight::Unit::Pound).should eq BigDecimal.new("453.59237")
      end
    end
    
    describe ".metric_unit?" do
      it "identifies metric units correctly" do
        Unit::Weight.metric_unit?(Unit::Weight::Unit::Gram).should be_true
        Unit::Weight.metric_unit?(Unit::Weight::Unit::Kilogram).should be_true
        Unit::Weight.metric_unit?(Unit::Weight::Unit::Pound).should be_false
        Unit::Weight.metric_unit?(Unit::Weight::Unit::Ounce).should be_false
      end
    end
  end
  
  describe "instance methods" do
    
    describe "#symbol" do
      it "returns unit symbol" do
        weight_kg = Unit::Weight.new(2.5, Unit::Weight::Unit::Kilogram)
        weight_lb = Unit::Weight.new(5.5, Unit::Weight::Unit::Pound)
        
        weight_kg.symbol.should eq "kg"
        weight_lb.symbol.should eq "lb"
      end
    end
    
    describe "#unit_name" do
      it "returns singular unit name" do
        weight_kg = Unit::Weight.new(2.5, Unit::Weight::Unit::Kilogram)
        weight_lb = Unit::Weight.new(5.5, Unit::Weight::Unit::Pound)
        
        weight_kg.unit_name.should eq "kilogram"
        weight_lb.unit_name.should eq "pound"
      end
      
      it "returns plural unit name when requested" do
        weight_kg = Unit::Weight.new(2.5, Unit::Weight::Unit::Kilogram)
        weight_lb = Unit::Weight.new(5.5, Unit::Weight::Unit::Pound)
        
        weight_kg.unit_name(plural: true).should eq "kilograms"
        weight_lb.unit_name(plural: true).should eq "pounds"
      end
    end
  end
  
  describe "core functionality" do
    
    it "supports equality comparison" do
      weight1 = Unit::Weight.new(1000, Unit::Weight::Unit::Gram)
      weight2 = Unit::Weight.new(1, Unit::Weight::Unit::Kilogram)
      weight3 = Unit::Weight.new(1000, Unit::Weight::Unit::Gram)
      
      weight1.should_not eq weight2  # Different units, even if equivalent
      weight1.should eq weight3      # Same value and unit
    end
    
    it "supports hash functionality" do
      weight1 = Unit::Weight.new(1000, Unit::Weight::Unit::Gram)
      weight2 = Unit::Weight.new(1, Unit::Weight::Unit::Kilogram)
      weight3 = Unit::Weight.new(1000, Unit::Weight::Unit::Gram)
      
      weight1.hash.should eq weight3.hash
      weight1.hash.should_not eq weight2.hash
    end
    
    it "has string representation" do
      weight1 = Unit::Weight.new(1000, Unit::Weight::Unit::Gram)
      weight2 = Unit::Weight.new(1, Unit::Weight::Unit::Kilogram)
      
      weight1.to_s.should eq "1000.0 gram"
      weight2.to_s.should eq "1.0 kilogram"
    end
    
    it "has inspect functionality" do
      weight1 = Unit::Weight.new(1000, Unit::Weight::Unit::Gram)
      expected = "Weight(1000.0, Gram)"
      weight1.inspect.should eq expected
    end
  end
  
  describe "type safety" do
    it "ensures type safety for weight operations" do
      # This should compile - same types
      weight1 = Unit::Weight.new(100, Unit::Weight::Unit::Gram)
      weight2 = Unit::Weight.new(200, Unit::Weight::Unit::Gram)
      
      # These operations should be type-safe
      weight1.should_not eq weight2
      weight1.value.should be < weight2.value
    end
  end
end