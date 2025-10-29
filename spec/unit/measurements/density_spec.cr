require "../../spec_helper"

describe Unit::Density do
  describe ".new" do
    it "creates density with symbol unit" do
      density = Unit::Density.new(1.0, :gram_per_milliliter)
      density.value.should eq(BigDecimal.new("1.0"))
      density.unit.should eq(Unit::Density::Unit::GramPerMilliliter)
    end

    it "creates density with enum unit" do
      density = Unit::Density.new(62.4, Unit::Density::Unit::PoundPerCubicFoot)
      density.value.should eq(BigDecimal.new("62.4"))
      density.unit.should eq(Unit::Density::Unit::PoundPerCubicFoot)
    end

    it "accepts BigDecimal values" do
      density = Unit::Density.new(BigDecimal.new("1.5"), :kilogram_per_liter)
      density.value.should eq(BigDecimal.new("1.5"))
    end

    it "accepts BigRational values" do
      density = Unit::Density.new(BigRational.new(3, 2), :gram_per_milliliter)
      density.value.should eq(BigDecimal.new("1.5"))
    end

    it "raises error for NaN values" do
      expect_raises(ArgumentError, /Value cannot be NaN/) do
        Unit::Density.new(Float64::NAN, :gram_per_milliliter)
      end
    end

    it "raises error for infinite values" do
      expect_raises(ArgumentError, /Value cannot be infinite/) do
        Unit::Density.new(Float64::INFINITY, :gram_per_milliliter)
      end
    end

    it "raises error for zero density" do
      expect_raises(ArgumentError, /Density must be positive/) do
        Unit::Density.new(0, :gram_per_milliliter)
      end
    end

    it "raises error for negative density" do
      expect_raises(ArgumentError, /Density must be positive/) do
        Unit::Density.new(-1, :gram_per_milliliter)
      end
    end

    it "raises error for invalid unit symbol" do
      expect_raises(ArgumentError, /Invalid unit symbol/) do
        Unit::Density.new(1.0, :invalid_unit)
      end
    end
  end

  describe ".base_unit" do
    it "returns gram_per_milliliter as base unit" do
      Unit::Density.base_unit.should eq(Unit::Density::Unit::GramPerMilliliter)
    end
  end

  describe ".conversion_factor" do
    it "returns conversion factors for enum units" do
      Unit::Density.conversion_factor(Unit::Density::Unit::GramPerMilliliter).should eq(BigDecimal.new("1"))
      Unit::Density.conversion_factor(Unit::Density::Unit::KilogramPerLiter).should eq(BigDecimal.new("1"))
      Unit::Density.conversion_factor(Unit::Density::Unit::KilogramPerCubicMeter).should eq(BigDecimal.new("0.001"))
    end

    it "returns conversion factors for symbol units" do
      Unit::Density.conversion_factor(:gram_per_milliliter).should eq(BigDecimal.new("1"))
      Unit::Density.conversion_factor(:kg_per_l).should eq(BigDecimal.new("1"))
      Unit::Density.conversion_factor(:kg_per_m3).should eq(BigDecimal.new("0.001"))
    end

    it "raises error for invalid unit symbol" do
      expect_raises(ArgumentError, /Invalid unit symbol/) do
        Unit::Density.conversion_factor(:invalid_unit)
      end
    end
  end

  describe ".metric_unit?" do
    it "identifies metric units" do
      Unit::Density.metric_unit?(Unit::Density::Unit::GramPerMilliliter).should be_true
      Unit::Density.metric_unit?(Unit::Density::Unit::KilogramPerLiter).should be_true
      Unit::Density.metric_unit?(Unit::Density::Unit::GramPerCubicCentimeter).should be_true
    end

    it "identifies non-metric units" do
      Unit::Density.metric_unit?(Unit::Density::Unit::PoundPerGallon).should be_false
      Unit::Density.metric_unit?(Unit::Density::Unit::PoundPerCubicFoot).should be_false
    end
  end

  describe ".imperial_unit?" do
    it "identifies imperial units" do
      Unit::Density.imperial_unit?(Unit::Density::Unit::PoundPerGallon).should be_true
      Unit::Density.imperial_unit?(Unit::Density::Unit::PoundPerCubicFoot).should be_true
      Unit::Density.imperial_unit?(Unit::Density::Unit::OuncePerCubicInch).should be_true
    end

    it "identifies non-imperial units" do
      Unit::Density.imperial_unit?(Unit::Density::Unit::GramPerMilliliter).should be_false
      Unit::Density.imperial_unit?(Unit::Density::Unit::KilogramPerLiter).should be_false
    end
  end

  describe "#convert_to" do
    it "converts between metric units" do
      density = Unit::Density.new(1.0, :gram_per_milliliter)
      converted = density.convert_to(:kilogram_per_liter)
      converted.value.should be_close(BigDecimal.new("1.0"), BigDecimal.new("0.001"))
      converted.unit.should eq(Unit::Density::Unit::KilogramPerLiter)
    end

    it "converts to cubic meters" do
      density = Unit::Density.new(1000.0, :kilogram_per_cubic_meter)
      converted = density.convert_to(:gram_per_milliliter)
      converted.value.should be_close(BigDecimal.new("1.0"), BigDecimal.new("0.001"))
      converted.unit.should eq(Unit::Density::Unit::GramPerMilliliter)
    end

    it "converts between metric and imperial units" do
      density = Unit::Density.new(1.0, :gram_per_milliliter)
      converted = density.convert_to(:pound_per_gallon)
      converted.value.should be_close(BigDecimal.new("8.345404"), BigDecimal.new("0.001"))
      converted.unit.should eq(Unit::Density::Unit::PoundPerGallon)
    end

    it "converts from imperial units" do
      density = Unit::Density.new(62.4, :pound_per_cubic_foot)
      converted = density.convert_to(:gram_per_milliliter)
      converted.value.should be_close(BigDecimal.new("0.999552"), BigDecimal.new("0.001"))
      converted.unit.should eq(Unit::Density::Unit::GramPerMilliliter)
    end

    it "returns equivalent value when converting to same unit" do
      density = Unit::Density.new(1.0, :gram_per_milliliter)
      converted = density.convert_to(:gram_per_milliliter)
      converted.should eq(density)
    end
  end

  describe "#to" do
    it "aliases convert_to" do
      density = Unit::Density.new(1.0, :gram_per_milliliter)
      converted = density.to(:kilogram_per_liter)
      converted.value.should be_close(BigDecimal.new("1.0"), BigDecimal.new("0.001"))
      converted.unit.should eq(Unit::Density::Unit::KilogramPerLiter)
    end
  end

  describe "#symbol" do
    it "returns correct symbols" do
      Unit::Density.new(1.0, :gram_per_milliliter).symbol.should eq("g/mL")
      Unit::Density.new(1.0, :kilogram_per_liter).symbol.should eq("kg/L")
      Unit::Density.new(1.0, :gram_per_cubic_centimeter).symbol.should eq("g/cm³")
      Unit::Density.new(1.0, :pound_per_gallon).symbol.should eq("lb/gal")
      Unit::Density.new(1.0, :pound_per_cubic_foot).symbol.should eq("lb/ft³")
    end
  end

  describe "#unit_name" do
    it "returns correct unit names" do
      Unit::Density.new(1.0, :gram_per_milliliter).unit_name.should eq("gram per milliliter")
      Unit::Density.new(1.0, :kilogram_per_liter).unit_name.should eq("kilogram per liter")
      Unit::Density.new(1.0, :pound_per_gallon).unit_name.should eq("pound per gallon")
    end

    it "returns plural names when requested" do
      Unit::Density.new(1.0, :gram_per_milliliter).unit_name(plural: true).should eq("grams per milliliter")
      Unit::Density.new(1.0, :pound_per_gallon).unit_name(plural: true).should eq("pounds per gallon")
      Unit::Density.new(1.0, :pound_per_cubic_foot).unit_name(plural: true).should eq("pounds per cubic foot")
    end
  end

  describe "arithmetic operations" do
    it "supports addition" do
      density1 = Unit::Density.new(1.0, :gram_per_milliliter)
      density2 = Unit::Density.new(0.5, :gram_per_milliliter)
      result = density1 + density2
      result.value.should eq(BigDecimal.new("1.5"))
      result.unit.should eq(Unit::Density::Unit::GramPerMilliliter)
    end

    it "supports subtraction" do
      density1 = Unit::Density.new(1.0, :gram_per_milliliter)
      density2 = Unit::Density.new(0.3, :gram_per_milliliter)
      result = density1 - density2
      result.value.should eq(BigDecimal.new("0.7"))
      result.unit.should eq(Unit::Density::Unit::GramPerMilliliter)
    end

    it "supports multiplication by scalar" do
      density = Unit::Density.new(1.0, :gram_per_milliliter)
      result = density * 2
      result.value.should eq(BigDecimal.new("2.0"))
      result.unit.should eq(Unit::Density::Unit::GramPerMilliliter)
    end

    it "supports division by scalar" do
      density = Unit::Density.new(1.0, :gram_per_milliliter)
      result = density / 2
      result.value.should eq(BigDecimal.new("0.5"))
      result.unit.should eq(Unit::Density::Unit::GramPerMilliliter)
    end
  end

  describe "comparison operations" do
    it "supports equality with conversion" do
      density1 = Unit::Density.new(1.0, :gram_per_milliliter)
      density2 = Unit::Density.new(1.0, :kilogram_per_liter)
      density1.should eq(density2)
    end

    it "supports greater than with conversion" do
      density1 = Unit::Density.new(2.0, :gram_per_milliliter)
      density2 = Unit::Density.new(1.0, :kilogram_per_liter)
      density1.should be > density2
    end

    it "supports less than with conversion" do
      density1 = Unit::Density.new(0.5, :gram_per_milliliter)
      density2 = Unit::Density.new(1.0, :kilogram_per_liter)
      density1.should be < density2
    end
  end

  describe "string representation" do
    it "has readable to_s" do
      density = Unit::Density.new(1.0, :gram_per_milliliter)
      density.to_s.should eq("1.0 grampermilliliter")
    end

    it "has informative inspect" do
      density = Unit::Density.new(1.0, :gram_per_milliliter)
      density.inspect.should eq("Density(1.0, grampermilliliter)")
    end
  end

  describe "JSON serialization" do
    it "serializes to JSON" do
      density = Unit::Density.new(1.5, :gram_per_milliliter)
      json = density.to_json
      json.should contain(%("value":"1.5"))
      json.should contain(%("unit":"grampermilliliter"))
    end

    it "deserializes from JSON" do
      json = %({"value":"1.5","unit":"grampermilliliter"})
      density = Unit::Density.from_json(json)
      density.value.should eq(BigDecimal.new("1.5"))
      density.unit.should eq(Unit::Density::Unit::GramPerMilliliter)
    end
  end

  describe "YAML serialization" do
    it "serializes to YAML" do
      density = Unit::Density.new(1.5, :gram_per_milliliter)
      yaml = density.to_yaml
      yaml.should contain("value: 1.5")
      yaml.should contain("unit: grampermilliliter")
    end

    it "deserializes from YAML" do
      yaml = "---\nvalue: 1.5\nunit: grampermilliliter\n"
      density = Unit::Density.from_yaml(yaml)
      density.value.should eq(BigDecimal.new("1.5"))
      density.unit.should eq(Unit::Density::Unit::GramPerMilliliter)
    end
  end
end
