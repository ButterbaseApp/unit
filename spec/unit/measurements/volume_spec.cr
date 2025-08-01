require "../../spec_helper"
require "../../../src/unit/measurements/volume"

describe Unit::Volume do
  describe "initialization" do
    it "creates volume with liter unit" do
      volume = Unit::Volume.new(2.5, Unit::Volume::Unit::Liter)
      volume.value.should eq BigDecimal.new("2.5")
      volume.unit.should eq Unit::Volume::Unit::Liter
    end

    it "creates volume with cup unit" do
      volume = Unit::Volume.new(1.5, Unit::Volume::Unit::Cup)
      volume.value.should eq BigDecimal.new("1.5")
      volume.unit.should eq Unit::Volume::Unit::Cup
    end

    it "creates volume with gallon unit" do
      volume = Unit::Volume.new(5, Unit::Volume::Unit::Gallon)
      volume.value.should eq BigDecimal.new("5")
      volume.unit.should eq Unit::Volume::Unit::Gallon
    end

    it "handles various numeric types" do
      Unit::Volume.new(10_i32, Unit::Volume::Unit::Liter).value.should eq BigDecimal.new("10")
      Unit::Volume.new(10_i64, Unit::Volume::Unit::Liter).value.should eq BigDecimal.new("10")
      Unit::Volume.new(10.5_f32, Unit::Volume::Unit::Liter).value.should eq BigDecimal.new("10.5")
      Unit::Volume.new(10.5_f64, Unit::Volume::Unit::Liter).value.should eq BigDecimal.new("10.5")
    end

    it "rejects invalid float values" do
      expect_raises(ArgumentError, "Value cannot be NaN") do
        Unit::Volume.new(Float64::NAN, Unit::Volume::Unit::Liter)
      end

      expect_raises(ArgumentError, "Value cannot be infinite") do
        Unit::Volume.new(Float64::INFINITY, Unit::Volume::Unit::Liter)
      end
    end

    describe "symbol constructor" do
      it "creates volume with symbol units" do
        volume1 = Unit::Volume.new(2.5, :liter)
        volume1.value.should eq BigDecimal.new("2.5")
        volume1.unit.should eq Unit::Volume::Unit::Liter

        volume2 = Unit::Volume.new(1, :gallon)
        volume2.value.should eq BigDecimal.new("1")
        volume2.unit.should eq Unit::Volume::Unit::Gallon

        volume3 = Unit::Volume.new(16, :cup)
        volume3.value.should eq BigDecimal.new("16")
        volume3.unit.should eq Unit::Volume::Unit::Cup
      end

      it "handles capitalized symbols" do
        volume = Unit::Volume.new(1.5, :Liter)
        volume.value.should eq BigDecimal.new("1.5")
        volume.unit.should eq Unit::Volume::Unit::Liter
      end

      it "raises error for invalid symbols" do
        expect_raises(ArgumentError, /Invalid unit symbol: invalid_unit/) do
          Unit::Volume.new(1, :invalid_unit)
        end
      end
    end
  end

  describe "Unit enum" do
    it "has all expected units" do
      units = Unit::Volume::Unit.values
      units.should contain Unit::Volume::Unit::Liter
      units.should contain Unit::Volume::Unit::Milliliter
      units.should contain Unit::Volume::Unit::Gallon
      units.should contain Unit::Volume::Unit::Quart
      units.should contain Unit::Volume::Unit::Pint
      units.should contain Unit::Volume::Unit::Cup
      units.should contain Unit::Volume::Unit::FluidOunce
    end

    it "supports unit aliases" do
      Unit::Volume::Unit::L.should eq Unit::Volume::Unit::Liter
      Unit::Volume::Unit::Ml.should eq Unit::Volume::Unit::Milliliter
      Unit::Volume::Unit::Gal.should eq Unit::Volume::Unit::Gallon
      Unit::Volume::Unit::Qt.should eq Unit::Volume::Unit::Quart
      Unit::Volume::Unit::Pt.should eq Unit::Volume::Unit::Pint
      Unit::Volume::Unit::FlOz.should eq Unit::Volume::Unit::FluidOunce
    end

    describe "#metric?" do
      it "identifies metric units correctly" do
        Unit::Volume::Unit::Liter.metric?.should be_true
        Unit::Volume::Unit::Milliliter.metric?.should be_true

        Unit::Volume::Unit::Gallon.metric?.should be_false
        Unit::Volume::Unit::Quart.metric?.should be_false
        Unit::Volume::Unit::Pint.metric?.should be_false
        Unit::Volume::Unit::Cup.metric?.should be_false
        Unit::Volume::Unit::FluidOunce.metric?.should be_false
      end
    end

    describe "#symbol" do
      it "returns correct symbols" do
        Unit::Volume::Unit::Liter.symbol.should eq "L"
        Unit::Volume::Unit::Milliliter.symbol.should eq "mL"
        Unit::Volume::Unit::Gallon.symbol.should eq "gal"
        Unit::Volume::Unit::Quart.symbol.should eq "qt"
        Unit::Volume::Unit::Pint.symbol.should eq "pt"
        Unit::Volume::Unit::Cup.symbol.should eq "cup"
        Unit::Volume::Unit::FluidOunce.symbol.should eq "fl oz"
      end
    end

    describe "#name" do
      it "returns singular names" do
        Unit::Volume::Unit::Liter.name.should eq "liter"
        Unit::Volume::Unit::Milliliter.name.should eq "milliliter"
        Unit::Volume::Unit::Gallon.name.should eq "gallon"
        Unit::Volume::Unit::Cup.name.should eq "cup"
        Unit::Volume::Unit::FluidOunce.name.should eq "fluid ounce"
      end

      it "returns plural names when requested" do
        Unit::Volume::Unit::Liter.name(plural: true).should eq "liters"
        Unit::Volume::Unit::Milliliter.name(plural: true).should eq "milliliters"
        Unit::Volume::Unit::Gallon.name(plural: true).should eq "gallons"
        Unit::Volume::Unit::Cup.name(plural: true).should eq "cups"
        Unit::Volume::Unit::FluidOunce.name(plural: true).should eq "fluid ounces"
      end
    end
  end

  describe "conversion factors" do
    it "has correct conversion factors based on NIST standards" do
      Unit::Volume::CONVERSION_FACTORS[Unit::Volume::Unit::Liter].should eq BigDecimal.new("1")
      Unit::Volume::CONVERSION_FACTORS[Unit::Volume::Unit::Milliliter].should eq BigDecimal.new("0.001")
      Unit::Volume::CONVERSION_FACTORS[Unit::Volume::Unit::Gallon].should eq BigDecimal.new("3.785411784")
      Unit::Volume::CONVERSION_FACTORS[Unit::Volume::Unit::Quart].should eq BigDecimal.new("0.946352946")
      Unit::Volume::CONVERSION_FACTORS[Unit::Volume::Unit::Pint].should eq BigDecimal.new("0.473176473")
      Unit::Volume::CONVERSION_FACTORS[Unit::Volume::Unit::Cup].should eq BigDecimal.new("0.2365882365")
      Unit::Volume::CONVERSION_FACTORS[Unit::Volume::Unit::FluidOunce].should eq BigDecimal.new("0.0295735295625")
    end

    it "validates US liquid measurement relationships" do
      gallon_factor = Unit::Volume::CONVERSION_FACTORS[Unit::Volume::Unit::Gallon]
      quart_factor = Unit::Volume::CONVERSION_FACTORS[Unit::Volume::Unit::Quart]
      pint_factor = Unit::Volume::CONVERSION_FACTORS[Unit::Volume::Unit::Pint]
      cup_factor = Unit::Volume::CONVERSION_FACTORS[Unit::Volume::Unit::Cup]
      fl_oz_factor = Unit::Volume::CONVERSION_FACTORS[Unit::Volume::Unit::FluidOunce]

      # 4 quarts should equal 1 gallon
      (quart_factor * BigDecimal.new("4")).should eq gallon_factor

      # 2 pints should equal 1 quart
      (pint_factor * BigDecimal.new("2")).should eq quart_factor

      # 2 cups should equal 1 pint
      (cup_factor * BigDecimal.new("2")).should eq pint_factor

      # 8 fluid ounces should equal 1 cup
      (fl_oz_factor * BigDecimal.new("8")).should eq cup_factor

      # 128 fluid ounces should equal 1 gallon (1 gal = 4 qt = 8 pt = 16 cups = 128 fl oz)
      (fl_oz_factor * BigDecimal.new("128")).should eq gallon_factor
    end

    it "validates metric system relationships" do
      liter_factor = Unit::Volume::CONVERSION_FACTORS[Unit::Volume::Unit::Liter]
      ml_factor = Unit::Volume::CONVERSION_FACTORS[Unit::Volume::Unit::Milliliter]

      # 1000 milliliters should equal 1 liter
      (ml_factor * BigDecimal.new("1000")).should eq liter_factor
    end
  end

  describe "class methods" do
    describe ".base_unit" do
      it "returns liter as base unit" do
        Unit::Volume.base_unit.should eq Unit::Volume::Unit::Liter
      end
    end

    describe ".conversion_factor" do
      it "returns correct conversion factors" do
        Unit::Volume.conversion_factor(Unit::Volume::Unit::Gallon).should eq BigDecimal.new("3.785411784")
        Unit::Volume.conversion_factor(Unit::Volume::Unit::Cup).should eq BigDecimal.new("0.2365882365")
        Unit::Volume.conversion_factor(Unit::Volume::Unit::FluidOunce).should eq BigDecimal.new("0.0295735295625")
      end

      it "accepts symbol units" do
        Unit::Volume.conversion_factor(:gallon).should eq BigDecimal.new("3.785411784")
        Unit::Volume.conversion_factor(:cup).should eq BigDecimal.new("0.2365882365")
        Unit::Volume.conversion_factor(:liter).should eq BigDecimal.new("1")
        Unit::Volume.conversion_factor(:milliliter).should eq BigDecimal.new("0.001")
      end

      it "handles capitalized symbol units" do
        Unit::Volume.conversion_factor(:Gallon).should eq BigDecimal.new("3.785411784")
        Unit::Volume.conversion_factor(:Liter).should eq BigDecimal.new("1")
      end

      it "raises error for invalid symbol units" do
        expect_raises(ArgumentError, /Invalid unit symbol: invalid_unit/) do
          Unit::Volume.conversion_factor(:invalid_unit)
        end
      end
    end

    describe ".metric_unit?" do
      it "identifies metric units correctly" do
        Unit::Volume.metric_unit?(Unit::Volume::Unit::Liter).should be_true
        Unit::Volume.metric_unit?(Unit::Volume::Unit::Milliliter).should be_true
        Unit::Volume.metric_unit?(Unit::Volume::Unit::Gallon).should be_false
        Unit::Volume.metric_unit?(Unit::Volume::Unit::Cup).should be_false
      end
    end

    describe ".us_liquid_unit?" do
      it "identifies US liquid units correctly" do
        Unit::Volume.us_liquid_unit?(Unit::Volume::Unit::Gallon).should be_true
        Unit::Volume.us_liquid_unit?(Unit::Volume::Unit::Quart).should be_true
        Unit::Volume.us_liquid_unit?(Unit::Volume::Unit::Pint).should be_true
        Unit::Volume.us_liquid_unit?(Unit::Volume::Unit::Cup).should be_true
        Unit::Volume.us_liquid_unit?(Unit::Volume::Unit::FluidOunce).should be_true

        Unit::Volume.us_liquid_unit?(Unit::Volume::Unit::Liter).should be_false
        Unit::Volume.us_liquid_unit?(Unit::Volume::Unit::Milliliter).should be_false
      end
    end
  end

  describe "instance methods" do
    describe "#symbol" do
      it "returns unit symbol" do
        volume_l = Unit::Volume.new(2.5, Unit::Volume::Unit::Liter)
        volume_cup = Unit::Volume.new(1.5, Unit::Volume::Unit::Cup)
        volume_fl_oz = Unit::Volume.new(8, Unit::Volume::Unit::FluidOunce)

        volume_l.symbol.should eq "L"
        volume_cup.symbol.should eq "cup"
        volume_fl_oz.symbol.should eq "fl oz"
      end
    end

    describe "#unit_name" do
      it "returns singular unit name" do
        volume_l = Unit::Volume.new(2.5, Unit::Volume::Unit::Liter)
        volume_cup = Unit::Volume.new(1.5, Unit::Volume::Unit::Cup)
        volume_fl_oz = Unit::Volume.new(8, Unit::Volume::Unit::FluidOunce)

        volume_l.unit_name.should eq "liter"
        volume_cup.unit_name.should eq "cup"
        volume_fl_oz.unit_name.should eq "fluid ounce"
      end

      it "returns plural unit name when requested" do
        volume_l = Unit::Volume.new(2.5, Unit::Volume::Unit::Liter)
        volume_cup = Unit::Volume.new(1.5, Unit::Volume::Unit::Cup)
        volume_fl_oz = Unit::Volume.new(8, Unit::Volume::Unit::FluidOunce)

        volume_l.unit_name(plural: true).should eq "liters"
        volume_cup.unit_name(plural: true).should eq "cups"
        volume_fl_oz.unit_name(plural: true).should eq "fluid ounces"
      end
    end
  end

  describe "core functionality" do
    it "supports equality comparison with unit conversion" do
      volume1 = Unit::Volume.new(500, Unit::Volume::Unit::Milliliter)
      volume2 = Unit::Volume.new(0.5, Unit::Volume::Unit::Liter)
      volume3 = Unit::Volume.new(500, Unit::Volume::Unit::Milliliter)
      volume4 = Unit::Volume.new(250, Unit::Volume::Unit::Milliliter)

      volume1.should eq volume2     # Equivalent measurements are equal
      volume1.should eq volume3     # Same value and unit
      volume1.should_not eq volume4 # Different quantities
    end

    it "supports hash functionality with equivalent measurements" do
      volume1 = Unit::Volume.new(500, Unit::Volume::Unit::Milliliter)
      volume2 = Unit::Volume.new(0.5, Unit::Volume::Unit::Liter)
      volume3 = Unit::Volume.new(500, Unit::Volume::Unit::Milliliter)
      volume4 = Unit::Volume.new(250, Unit::Volume::Unit::Milliliter)

      volume1.hash.should eq volume2.hash     # Equivalent measurements have equal hashes
      volume1.hash.should eq volume3.hash     # Same measurements have equal hashes
      volume1.hash.should_not eq volume4.hash # Different quantities have different hashes
    end

    it "has string representation" do
      volume1 = Unit::Volume.new(500, Unit::Volume::Unit::Milliliter)
      volume2 = Unit::Volume.new(2.5, Unit::Volume::Unit::Cup)
      volume3 = Unit::Volume.new(8, Unit::Volume::Unit::FluidOunce)

      volume1.to_s.should eq "500.0 milliliter"
      volume2.to_s.should eq "2.5 cup"
      volume3.to_s.should eq "8.0 fluidounce"
    end

    it "has inspect functionality" do
      volume1 = Unit::Volume.new(500, Unit::Volume::Unit::Milliliter)
      expected = "Volume(500.0, Milliliter)"
      volume1.inspect.should eq expected
    end
  end

  describe "type safety" do
    it "ensures type safety for volume operations" do
      # This should compile - same types
      volume1 = Unit::Volume.new(250, Unit::Volume::Unit::Milliliter)
      volume2 = Unit::Volume.new(500, Unit::Volume::Unit::Milliliter)

      # These operations should be type-safe
      volume1.should_not eq volume2
      volume1.value.should be < volume2.value
    end
  end

  describe "cooking precision validation" do
    it "maintains precision for common recipe conversions" do
      # Test that conversion factors maintain cooking precision
      cup_factor = Unit::Volume.conversion_factor(Unit::Volume::Unit::Cup)
      fl_oz_factor = Unit::Volume.conversion_factor(Unit::Volume::Unit::FluidOunce)

      # 1 cup = 8 fluid ounces (exact)
      (fl_oz_factor * BigDecimal.new("8")).should eq cup_factor

      # Verify precision is maintained in string representation
      cup_factor.to_s.should eq "0.2365882365"
      fl_oz_factor.to_s.should eq "0.0295735295625"
    end

    it "handles fractional measurements accurately" do
      # Test common fractional measurements used in cooking
      volume_half_cup = Unit::Volume.new(0.5, Unit::Volume::Unit::Cup)
      volume_quarter_cup = Unit::Volume.new(0.25, Unit::Volume::Unit::Cup)

      volume_half_cup.value.should eq BigDecimal.new("0.5")
      volume_quarter_cup.value.should eq BigDecimal.new("0.25")
    end
  end
end
