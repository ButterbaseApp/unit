require "../spec_helper"

# Ensure all measurement types are loaded
require "../../src/unit/measurements/weight"
require "../../src/unit/measurements/length"
require "../../src/unit/measurements/volume"

describe Unit::Formatter do
  describe "#format" do
    context "with default parameters" do
      it "formats with 2 decimal places and long unit names" do
        weight = Unit::Weight.new(10.5, Unit::Weight::Unit::Kilogram)
        weight.format.should eq("10.50 kilogram")
      end
      
      it "formats integer values with decimals" do
        weight = Unit::Weight.new(10, Unit::Weight::Unit::Kilogram)
        weight.format.should eq("10.00 kilogram")
      end
      
      it "handles negative values" do
        weight = Unit::Weight.new(-5.5, Unit::Weight::Unit::Kilogram)
        weight.format.should eq("-5.50 kilogram")
      end
    end
    
    context "with precision parameter" do
      it "formats with specified precision" do
        weight = Unit::Weight.new(10.12345, Unit::Weight::Unit::Kilogram)
        weight.format(precision: 1).should eq("10.1 kilogram")
        weight.format(precision: 3).should eq("10.123 kilogram")
        weight.format(precision: 0).should eq("10 kilogram")
      end
      
      it "clamps precision to reasonable bounds" do
        weight = Unit::Weight.new(10.12345, Unit::Weight::Unit::Kilogram)
        weight.format(precision: -1).should eq("10 kilogram") # Clamped to 0
        weight.format(precision: 15).should eq("10.1234500000 kilogram") # Clamped to 10
      end
      
      it "handles whole numbers with zero precision" do
        weight = Unit::Weight.new(10, Unit::Weight::Unit::Kilogram)
        weight.format(precision: 0).should eq("10 kilogram")
      end
    end
    
    context "with unit_format parameter" do
      it "formats with short unit names" do
        weight = Unit::Weight.new(10.5, Unit::Weight::Unit::Kilogram)
        weight.format(unit_format: :short).should eq("10.50 kg")
      end
      
      it "formats with long unit names" do
        weight = Unit::Weight.new(10.5, Unit::Weight::Unit::Kilogram)
        weight.format(unit_format: :long).should eq("10.50 kilogram")
      end
      
      it "works with different measurement types" do
        length = Unit::Length.new(5.5, Unit::Length::Unit::Meter)
        length.format(unit_format: :short).should eq("5.50 m")
        
        volume = Unit::Volume.new(2.5, Unit::Volume::Unit::Liter)
        volume.format(unit_format: :short).should eq("2.50 L")
      end
    end
    
    context "with combined parameters" do
      it "formats with both precision and unit format" do
        weight = Unit::Weight.new(10.12345, Unit::Weight::Unit::Kilogram)
        weight.format(precision: 1, unit_format: :short).should eq("10.1 kg")
        weight.format(precision: 3, unit_format: :long).should eq("10.123 kilogram")
      end
    end
  end
  
  describe "#humanize" do
    context "with singular values" do
      it "uses singular form for 1" do
        weight = Unit::Weight.new(1, Unit::Weight::Unit::Kilogram)
        weight.humanize.should eq("1 kilogram")
      end
      
      it "uses singular form for -1" do
        weight = Unit::Weight.new(-1, Unit::Weight::Unit::Kilogram)
        weight.humanize.should eq("-1 kilogram")
      end
    end
    
    context "with plural values" do
      it "uses plural form for 0" do
        weight = Unit::Weight.new(0, Unit::Weight::Unit::Kilogram)
        weight.humanize.should eq("0 kilograms")
      end
      
      it "uses plural form for values > 1" do
        weight = Unit::Weight.new(2, Unit::Weight::Unit::Kilogram)
        weight.humanize.should eq("2 kilograms")
        
        weight = Unit::Weight.new(10.5, Unit::Weight::Unit::Kilogram)
        weight.humanize.should eq("10.5 kilograms")
      end
      
      it "uses plural form for negative values != -1" do
        weight = Unit::Weight.new(-2, Unit::Weight::Unit::Kilogram)
        weight.humanize.should eq("-2 kilograms")
        
        weight = Unit::Weight.new(-0.5, Unit::Weight::Unit::Kilogram)
        weight.humanize.should eq("-0.5 kilograms")
      end
    end
    
    context "with decimal formatting" do
      it "removes trailing zeros" do
        weight = Unit::Weight.new(10.50, Unit::Weight::Unit::Kilogram)
        weight.humanize.should eq("10.5 kilograms")
      end
      
      it "removes unnecessary decimal points" do
        weight = Unit::Weight.new(10.0, Unit::Weight::Unit::Kilogram)
        weight.humanize.should eq("10 kilograms")
      end
      
      it "preserves necessary decimals" do
        weight = Unit::Weight.new(10.25, Unit::Weight::Unit::Kilogram)
        weight.humanize.should eq("10.25 kilograms")
      end
    end
    
    context "with different measurement types" do
      it "works with Length measurements" do
        length = Unit::Length.new(1, Unit::Length::Unit::Meter)
        length.humanize.should eq("1 meter")
        
        length = Unit::Length.new(2.5, Unit::Length::Unit::Meter)
        length.humanize.should eq("2.5 meters")
      end
      
      it "works with Volume measurements" do
        volume = Unit::Volume.new(1, Unit::Volume::Unit::Liter)
        volume.humanize.should eq("1 liter")
        
        volume = Unit::Volume.new(3.5, Unit::Volume::Unit::Liter)
        volume.humanize.should eq("3.5 liters")
      end
      
      it "handles compound unit names" do
        volume = Unit::Volume.new(2, Unit::Volume::Unit::FluidOunce)
        volume.humanize.should eq("2 fluid ounces")
      end
    end
  end
  
  describe "#to_s backward compatibility" do
    it "maintains existing behavior for measurement to_s" do
      weight = Unit::Weight.new(10.5, Unit::Weight::Unit::Kilogram)
      weight.to_s.should eq("10.5 kilogram")
      
      weight_int = Unit::Weight.new(500, Unit::Weight::Unit::Gram)
      weight_int.to_s.should eq("500.0 gram")
    end
    
    it "handles different measurement types consistently" do
      length = Unit::Length.new(5.75, Unit::Length::Unit::Meter)
      length.to_s.should eq("5.75 meter")
      
      volume = Unit::Volume.new(2, Unit::Volume::Unit::Liter)
      volume.to_s.should eq("2.0 liter")
    end
  end
end