require "../spec_helper"
require "../../src/unit/parser"
require "../../src/unit/measurements/weight"
require "../../src/unit/measurements/length"

describe Unit::Parser do
  describe "FRACTION_REGEX" do
    it "matches simple fractions" do
      Unit::Parser::FRACTION_REGEX.match("1/2").should_not be_nil
      Unit::Parser::FRACTION_REGEX.match("3/4").should_not be_nil
      Unit::Parser::FRACTION_REGEX.match("10/3").should_not be_nil
    end
    
    it "matches negative fractions" do
      Unit::Parser::FRACTION_REGEX.match("-1/2").should_not be_nil
      Unit::Parser::FRACTION_REGEX.match("-10/3").should_not be_nil
    end
    
    it "captures numerator and denominator" do 
      match = Unit::Parser::FRACTION_REGEX.match("1/2")
      match.should_not be_nil
      match.not_nil![1].should eq("1")
      match.not_nil![2].should eq("2")
      
      match = Unit::Parser::FRACTION_REGEX.match("-10/3")
      match.should_not be_nil
      match.not_nil![1].should eq("-10")
      match.not_nil![2].should eq("3")
    end
    
    it "does not match invalid formats" do
      Unit::Parser::FRACTION_REGEX.match("1/").should be_nil
      Unit::Parser::FRACTION_REGEX.match("/2").should be_nil
      Unit::Parser::FRACTION_REGEX.match("1.5/2").should be_nil
      Unit::Parser::FRACTION_REGEX.match("1 / 2").should be_nil
      Unit::Parser::FRACTION_REGEX.match("1/2/3").should be_nil
    end
  end
  
  describe "DECIMAL_REGEX" do
    it "matches integers" do
      Unit::Parser::DECIMAL_REGEX.match("10").should_not be_nil
      Unit::Parser::DECIMAL_REGEX.match("-5").should_not be_nil
      Unit::Parser::DECIMAL_REGEX.match("0").should_not be_nil
    end
    
    it "matches decimals" do
      Unit::Parser::DECIMAL_REGEX.match("10.5").should_not be_nil
      Unit::Parser::DECIMAL_REGEX.match("-3.14").should_not be_nil
      Unit::Parser::DECIMAL_REGEX.match("0.001").should_not be_nil
      Unit::Parser::DECIMAL_REGEX.match("00.123").should_not be_nil
    end
    
    it "matches negative numbers" do
      Unit::Parser::DECIMAL_REGEX.match("-5").should_not be_nil
      Unit::Parser::DECIMAL_REGEX.match("-5.5").should_not be_nil
    end
    
    it "does not match invalid formats" do
      Unit::Parser::DECIMAL_REGEX.match("10.").should be_nil
      Unit::Parser::DECIMAL_REGEX.match(".5").should be_nil
      Unit::Parser::DECIMAL_REGEX.match("10.5.2").should be_nil
      Unit::Parser::DECIMAL_REGEX.match("1 0").should be_nil
      Unit::Parser::DECIMAL_REGEX.match("abc").should be_nil
    end
  end
  
  describe "MEASUREMENT_REGEX" do
    it "matches decimal measurements with space" do
      match = Unit::Parser::MEASUREMENT_REGEX.match("10 kg")
      match.should_not be_nil
      match.not_nil![1].should eq("10")
      match.not_nil![2].should eq("kg")
      
      match = Unit::Parser::MEASUREMENT_REGEX.match("-5.5 pounds")
      match.should_not be_nil
      match.not_nil![1].should eq("-5.5")
      match.not_nil![2].should eq("pounds")
    end
    
    it "matches fraction measurements" do
      match = Unit::Parser::MEASUREMENT_REGEX.match("1/2 pound")
      match.should_not be_nil
      match.not_nil![1].should eq("1/2")
      match.not_nil![2].should eq("pound")
      
      match = Unit::Parser::MEASUREMENT_REGEX.match("-3/4 meters")
      match.should_not be_nil
      match.not_nil![1].should eq("-3/4")
      match.not_nil![2].should eq("meters")
    end
    
    it "matches measurements without space" do
      match = Unit::Parser::MEASUREMENT_REGEX.match("5.5kg")
      match.should_not be_nil
      match.not_nil![1].should eq("5.5")
      match.not_nil![2].should eq("kg")
    end
    
    it "handles flexible whitespace" do
      Unit::Parser::MEASUREMENT_REGEX.match("10  kg").should_not be_nil
      Unit::Parser::MEASUREMENT_REGEX.match("10\tkg").should_not be_nil
      Unit::Parser::MEASUREMENT_REGEX.match("10    kg").should_not be_nil
    end
    
    it "matches various unit formats" do
      Unit::Parser::MEASUREMENT_REGEX.match("10 kg").should_not be_nil
      Unit::Parser::MEASUREMENT_REGEX.match("10 kilogram").should_not be_nil
      Unit::Parser::MEASUREMENT_REGEX.match("10 KILOGRAMS").should_not be_nil
      Unit::Parser::MEASUREMENT_REGEX.match("10 g").should_not be_nil
      Unit::Parser::MEASUREMENT_REGEX.match("10 meters").should_not be_nil
    end
    
    it "does not match invalid formats" do
      Unit::Parser::MEASUREMENT_REGEX.match("kg 10").should be_nil
      Unit::Parser::MEASUREMENT_REGEX.match("10").should be_nil
      Unit::Parser::MEASUREMENT_REGEX.match("kg").should be_nil
      Unit::Parser::MEASUREMENT_REGEX.match("10 kg pounds").should be_nil
      Unit::Parser::MEASUREMENT_REGEX.match("").should be_nil
    end
  end
  
  describe "parse_value" do
    it "parses fractions as BigRational" do
      result = Unit::Parser.parse_value("1/2")
      result.should be_a(BigRational)
      result.should eq(BigRational.new(1, 2))
      
      result = Unit::Parser.parse_value("3/4")
      result.should be_a(BigRational)
      result.should eq(BigRational.new(3, 4))
      
      result = Unit::Parser.parse_value("10/3")
      result.should be_a(BigRational)
      result.should eq(BigRational.new(10, 3))
    end
    
    it "parses negative fractions" do
      result = Unit::Parser.parse_value("-1/2")
      result.should be_a(BigRational)
      result.should eq(BigRational.new(-1, 2))
      
      result = Unit::Parser.parse_value("-10/3")
      result.should be_a(BigRational)
      result.should eq(BigRational.new(-10, 3))
    end
    
    it "parses decimal values as BigDecimal" do
      result = Unit::Parser.parse_value("10.5")
      result.should be_a(BigDecimal)
      result.should eq(BigDecimal.new("10.5"))
      
      result = Unit::Parser.parse_value("-3.14")
      result.should be_a(BigDecimal)
      result.should eq(BigDecimal.new("-3.14"))
      
      result = Unit::Parser.parse_value("0.001")
      result.should be_a(BigDecimal)
      result.should eq(BigDecimal.new("0.001"))
    end
    
    it "parses integers as BigDecimal" do
      result = Unit::Parser.parse_value("10")
      result.should be_a(BigDecimal)
      result.should eq(BigDecimal.new("10"))
      
      result = Unit::Parser.parse_value("-5")
      result.should be_a(BigDecimal)
      result.should eq(BigDecimal.new("-5"))
      
      result = Unit::Parser.parse_value("0")
      result.should be_a(BigDecimal)
      result.should eq(BigDecimal.new("0"))
    end
    
    it "handles edge cases" do
      result = Unit::Parser.parse_value("1")
      result.should be_a(BigDecimal)
      result.should eq(BigDecimal.new("1"))
      
      result = Unit::Parser.parse_value("1/1")
      result.should be_a(BigRational)
      result.should eq(BigRational.new(1, 1))
    end
    
    it "handles whitespace" do
      result = Unit::Parser.parse_value(" 10.5 ")
      result.should be_a(BigDecimal)
      result.should eq(BigDecimal.new("10.5"))
      
      result = Unit::Parser.parse_value(" 1/2 ")
      result.should be_a(BigRational)
      result.should eq(BigRational.new(1, 2))
    end
    
    it "raises ArgumentError for division by zero" do
      expect_raises(ArgumentError, "Division by zero in fraction: 1/0") do
        Unit::Parser.parse_value("1/0")
      end
    end
    
    it "raises ArgumentError for invalid formats" do
      expect_raises(ArgumentError, "Invalid numeric value: abc") do
        Unit::Parser.parse_value("abc")
      end
      
      expect_raises(ArgumentError, "Invalid numeric value: 1/2/3") do
        Unit::Parser.parse_value("1/2/3")
      end
      
      expect_raises(ArgumentError, "Invalid numeric value: 10.") do
        Unit::Parser.parse_value("10.")
      end
      
      expect_raises(ArgumentError, "Invalid numeric value: .5") do
        Unit::Parser.parse_value(".5")
      end
    end
  end
  
  describe "parse_unit" do
    it "matches enum string representation for Weight" do
      result = Unit::Parser.parse_unit(Unit::Weight, "kilogram")
      result.should eq(Unit::Weight::Unit::Kilogram)
      
      result = Unit::Parser.parse_unit(Unit::Weight, "POUND")
      result.should eq(Unit::Weight::Unit::Pound)
      
      result = Unit::Parser.parse_unit(Unit::Weight, "gram")
      result.should eq(Unit::Weight::Unit::Gram)
    end
    
    it "matches unit symbols for Weight" do
      result = Unit::Parser.parse_unit(Unit::Weight, "kg")
      result.should eq(Unit::Weight::Unit::Kilogram)
      
      result = Unit::Parser.parse_unit(Unit::Weight, "g")
      result.should eq(Unit::Weight::Unit::Gram)
      
      result = Unit::Parser.parse_unit(Unit::Weight, "lb")
      result.should eq(Unit::Weight::Unit::Pound)
      
      result = Unit::Parser.parse_unit(Unit::Weight, "oz")
      result.should eq(Unit::Weight::Unit::Ounce)
    end
    
    it "matches unit names for Weight" do
      result = Unit::Parser.parse_unit(Unit::Weight, "kilogram")
      result.should eq(Unit::Weight::Unit::Kilogram)
      
      result = Unit::Parser.parse_unit(Unit::Weight, "pound")
      result.should eq(Unit::Weight::Unit::Pound)
      
      result = Unit::Parser.parse_unit(Unit::Weight, "ounce") 
      result.should eq(Unit::Weight::Unit::Ounce)
    end
    
    it "matches plural unit names for Weight" do
      result = Unit::Parser.parse_unit(Unit::Weight, "kilograms")
      result.should eq(Unit::Weight::Unit::Kilogram)
      
      result = Unit::Parser.parse_unit(Unit::Weight, "pounds")
      result.should eq(Unit::Weight::Unit::Pound)
      
      result = Unit::Parser.parse_unit(Unit::Weight, "ounces")
      result.should eq(Unit::Weight::Unit::Ounce)
    end
    
    it "matches enum string representation for Length" do
      result = Unit::Parser.parse_unit(Unit::Length, "meter")
      result.should eq(Unit::Length::Unit::Meter)
      
      result = Unit::Parser.parse_unit(Unit::Length, "FOOT")
      result.should eq(Unit::Length::Unit::Foot)
      
      result = Unit::Parser.parse_unit(Unit::Length, "inch")
      result.should eq(Unit::Length::Unit::Inch)
    end
    
    it "matches unit symbols for Length" do
      result = Unit::Parser.parse_unit(Unit::Length, "m")
      result.should eq(Unit::Length::Unit::Meter)
      
      result = Unit::Parser.parse_unit(Unit::Length, "cm")
      result.should eq(Unit::Length::Unit::Centimeter)
      
      result = Unit::Parser.parse_unit(Unit::Length, "ft")
      result.should eq(Unit::Length::Unit::Foot)
      
      result = Unit::Parser.parse_unit(Unit::Length, "in")
      result.should eq(Unit::Length::Unit::Inch)
    end
    
    it "is case insensitive" do
      Unit::Parser.parse_unit(Unit::Weight, "KG").should eq(Unit::Weight::Unit::Kilogram)
      Unit::Parser.parse_unit(Unit::Weight, "Pound").should eq(Unit::Weight::Unit::Pound)
      Unit::Parser.parse_unit(Unit::Length, "M").should eq(Unit::Length::Unit::Meter)
      Unit::Parser.parse_unit(Unit::Length, "INCHES").should eq(Unit::Length::Unit::Inch)
    end
    
    it "handles whitespace" do
      Unit::Parser.parse_unit(Unit::Weight, " kg ").should eq(Unit::Weight::Unit::Kilogram)
      Unit::Parser.parse_unit(Unit::Length, " meter ").should eq(Unit::Length::Unit::Meter)
    end
    
    it "handles special plural forms" do
      # Length has special pluralization: foot -> feet, inch -> inches  
      result = Unit::Parser.parse_unit(Unit::Length, "feet")
      result.should eq(Unit::Length::Unit::Foot)
      
      result = Unit::Parser.parse_unit(Unit::Length, "inches")
      result.should eq(Unit::Length::Unit::Inch)
    end
    
    it "raises ArgumentError for unknown units" do
      expect_raises(ArgumentError, "Unknown unit: xyz") do
        Unit::Parser.parse_unit(Unit::Weight, "xyz")
      end
      
      expect_raises(ArgumentError, "Unknown unit: invalid") do
        Unit::Parser.parse_unit(Unit::Length, "invalid")
      end
    end
  end
  
  describe "parse" do
    describe "Weight parsing" do
      it "parses decimal weights" do
        result = Unit::Parser.parse(Unit::Weight, "10.5 kg")
        result.should be_a(Unit::Weight)
        result.value.should eq(BigDecimal.new("10.5"))
        result.unit.should eq(Unit::Weight::Unit::Kilogram)
        
        result = Unit::Parser.parse(Unit::Weight, "-3.14 lb")
        result.value.should eq(BigDecimal.new("-3.14"))
        result.unit.should eq(Unit::Weight::Unit::Pound)
      end
      
      it "parses fractional weights" do
        result = Unit::Parser.parse(Unit::Weight, "1/2 pound")
        result.should be_a(Unit::Weight)
        result.value.should eq(BigRational.new(1, 2))
        result.unit.should eq(Unit::Weight::Unit::Pound)
        
        result = Unit::Parser.parse(Unit::Weight, "3/4 g")
        result.value.should eq(BigRational.new(3, 4))
        result.unit.should eq(Unit::Weight::Unit::Gram)
      end
      
      it "handles various unit formats" do
        Unit::Parser.parse(Unit::Weight, "10 kilogram").unit.should eq(Unit::Weight::Unit::Kilogram)
        Unit::Parser.parse(Unit::Weight, "10 POUND").unit.should eq(Unit::Weight::Unit::Pound)
        Unit::Parser.parse(Unit::Weight, "10 oz").unit.should eq(Unit::Weight::Unit::Ounce)
        Unit::Parser.parse(Unit::Weight, "10 pounds").unit.should eq(Unit::Weight::Unit::Pound)
      end
      
      it "handles flexible whitespace" do
        Unit::Parser.parse(Unit::Weight, "10kg").value.should eq(BigDecimal.new("10"))
        Unit::Parser.parse(Unit::Weight, "10  kg").value.should eq(BigDecimal.new("10"))
        Unit::Parser.parse(Unit::Weight, " 10 kg ").value.should eq(BigDecimal.new("10"))
        Unit::Parser.parse(Unit::Weight, "  10   kg  ").value.should eq(BigDecimal.new("10"))
        Unit::Parser.parse(Unit::Weight, "10\tkg").value.should eq(BigDecimal.new("10"))
      end
      
      it "handles all unit aliases" do
        # Test short form aliases
        Unit::Parser.parse(Unit::Weight, "10 g").unit.should eq(Unit::Weight::Unit::Gram)
        Unit::Parser.parse(Unit::Weight, "10 kg").unit.should eq(Unit::Weight::Unit::Kilogram)
        Unit::Parser.parse(Unit::Weight, "10 mg").unit.should eq(Unit::Weight::Unit::Milligram)
        Unit::Parser.parse(Unit::Weight, "10 t").unit.should eq(Unit::Weight::Unit::Tonne)
        Unit::Parser.parse(Unit::Weight, "10 lb").unit.should eq(Unit::Weight::Unit::Pound)
        Unit::Parser.parse(Unit::Weight, "10 oz").unit.should eq(Unit::Weight::Unit::Ounce)
      end
    end
    
    describe "Length parsing" do
      it "parses decimal lengths" do
        result = Unit::Parser.parse(Unit::Length, "10.5 m")
        result.should be_a(Unit::Length)
        result.value.should eq(BigDecimal.new("10.5"))
        result.unit.should eq(Unit::Length::Unit::Meter)
        
        result = Unit::Parser.parse(Unit::Length, "-3.14 ft")
        result.value.should eq(BigDecimal.new("-3.14"))
        result.unit.should eq(Unit::Length::Unit::Foot)
      end
      
      it "parses fractional lengths" do  
        result = Unit::Parser.parse(Unit::Length, "1/2 foot")
        result.should be_a(Unit::Length)
        result.value.should eq(BigRational.new(1, 2))
        result.unit.should eq(Unit::Length::Unit::Foot)
        
        result = Unit::Parser.parse(Unit::Length, "3/4 inch")
        result.value.should eq(BigRational.new(3, 4))
        result.unit.should eq(Unit::Length::Unit::Inch)
      end
      
      it "handles various unit formats" do
        Unit::Parser.parse(Unit::Length, "10 meter").unit.should eq(Unit::Length::Unit::Meter)
        Unit::Parser.parse(Unit::Length, "10 CM").unit.should eq(Unit::Length::Unit::Centimeter)
        Unit::Parser.parse(Unit::Length, "10 in").unit.should eq(Unit::Length::Unit::Inch)
        Unit::Parser.parse(Unit::Length, "10 feet").unit.should eq(Unit::Length::Unit::Foot)
        Unit::Parser.parse(Unit::Length, "10 inches").unit.should eq(Unit::Length::Unit::Inch)
      end
      
      it "handles all unit aliases" do
        # Test short form aliases
        Unit::Parser.parse(Unit::Length, "10 m").unit.should eq(Unit::Length::Unit::Meter)
        Unit::Parser.parse(Unit::Length, "10 cm").unit.should eq(Unit::Length::Unit::Centimeter)
        Unit::Parser.parse(Unit::Length, "10 mm").unit.should eq(Unit::Length::Unit::Millimeter)
        Unit::Parser.parse(Unit::Length, "10 km").unit.should eq(Unit::Length::Unit::Kilometer)
        Unit::Parser.parse(Unit::Length, "10 in").unit.should eq(Unit::Length::Unit::Inch)
        Unit::Parser.parse(Unit::Length, "10 ft").unit.should eq(Unit::Length::Unit::Foot)
        Unit::Parser.parse(Unit::Length, "10 yd").unit.should eq(Unit::Length::Unit::Yard)
        Unit::Parser.parse(Unit::Length, "10 mi").unit.should eq(Unit::Length::Unit::Mile)
      end
      
      it "handles flexible whitespace" do
        Unit::Parser.parse(Unit::Length, "10m").value.should eq(BigDecimal.new("10"))
        Unit::Parser.parse(Unit::Length, "10  m").value.should eq(BigDecimal.new("10"))
        Unit::Parser.parse(Unit::Length, " 10 m ").value.should eq(BigDecimal.new("10"))
        Unit::Parser.parse(Unit::Length, "  10   m  ").value.should eq(BigDecimal.new("10"))
        Unit::Parser.parse(Unit::Length, "10\tm").value.should eq(BigDecimal.new("10"))
      end
    end
    
    describe "Error handling" do
      it "raises ArgumentError for invalid format" do
        expect_raises(ArgumentError, "Invalid format: invalid") do
          Unit::Parser.parse(Unit::Weight, "invalid")
        end
        
        expect_raises(ArgumentError, "Invalid format: 10") do
          Unit::Parser.parse(Unit::Weight, "10")
        end
        
        expect_raises(ArgumentError, "Invalid format: kg") do
          Unit::Parser.parse(Unit::Length, "kg")
        end
      end
      
      it "raises ArgumentError for unknown units" do
        expect_raises(ArgumentError, "Unknown unit: xyz") do
          Unit::Parser.parse(Unit::Weight, "10 xyz")
        end
        
        expect_raises(ArgumentError, "Unknown unit: invalid") do
          Unit::Parser.parse(Unit::Length, "5 invalid")
        end
      end
      
      it "raises ArgumentError for invalid values" do
        expect_raises(ArgumentError, "Division by zero in fraction: 1/0") do
          Unit::Parser.parse(Unit::Weight, "1/0 kg")
        end
      end
    end
  end
end