require "../../spec_helper"

describe "Density Conversions" do
  describe "Weight to Volume conversions" do
    it "converts weight to volume using Density object" do
      weight = Unit::Weight.new(500, :gram)
      density = Unit::Density.new(1.0, :gram_per_milliliter)
      volume = weight.to_volume(density)

      volume.value.should be_close(BigDecimal.new("500.0"), BigDecimal.new("0.001"))
      volume.unit.should eq(Unit::Volume::Unit::Milliliter)
    end

    it "converts weight to volume using density value and unit" do
      weight = Unit::Weight.new(500, :gram)
      volume = weight.to_volume(1.0, :gram_per_milliliter)

      volume.value.should be_close(BigDecimal.new("500.0"), BigDecimal.new("0.001"))
      volume.unit.should eq(Unit::Volume::Unit::Milliliter)
    end

    it "converts different weight units correctly" do
      weight = Unit::Weight.new(1, :kilogram)
      density = Unit::Density.new(1.0, :gram_per_milliliter)
      volume = weight.to_volume(density)

      volume.value.should be_close(BigDecimal.new("1000.0"), BigDecimal.new("0.001"))
      volume.unit.should eq(Unit::Volume::Unit::Milliliter)
    end

    it "works with user-defined densities" do
      weight = Unit::Weight.new(200, :gram)
      flour_density = Unit::Density.new(0.593, :gram_per_milliliter)
      volume = weight.to_volume(flour_density)

      # Flour density = 0.593 g/mL
      # Volume = 200 g / 0.593 g/mL ≈ 337.27 mL
      volume.value.should be_close(BigDecimal.new("337.27"), BigDecimal.new("0.01"))
      volume.unit.should eq(Unit::Volume::Unit::Milliliter)
    end
  end

  describe "Volume to Weight conversions" do
    it "converts volume to weight using Density object" do
      volume = Unit::Volume.new(500, :milliliter)
      density = Unit::Density.new(1.0, :gram_per_milliliter)
      weight = volume.to_weight(density)

      weight.value.should be_close(BigDecimal.new("500.0"), BigDecimal.new("0.001"))
      weight.unit.should eq(Unit::Weight::Unit::Gram)
    end

    it "converts volume to weight using density value and unit" do
      volume = Unit::Volume.new(500, :milliliter)
      weight = volume.to_weight(1.0, :gram_per_milliliter)

      weight.value.should be_close(BigDecimal.new("500.0"), BigDecimal.new("0.001"))
      weight.unit.should eq(Unit::Weight::Unit::Gram)
    end

    it "converts different volume units correctly" do
      volume = Unit::Volume.new(1, :liter)
      density = Unit::Density.new(1.0, :gram_per_milliliter)
      weight = volume.to_weight(density)

      weight.value.should be_close(BigDecimal.new("1000.0"), BigDecimal.new("0.001"))
      weight.unit.should eq(Unit::Weight::Unit::Gram)
    end

    it "works with user-defined densities" do
      volume = Unit::Volume.new(250, :milliliter)
      honey_density = Unit::Density.new(1.42, :gram_per_milliliter)
      weight = volume.to_weight(honey_density)

      # Honey density = 1.42 g/mL
      # Weight = 250 mL * 1.42 g/mL = 355 g
      weight.value.should be_close(BigDecimal.new("355.0"), BigDecimal.new("0.1"))
      weight.unit.should eq(Unit::Weight::Unit::Gram)
    end
  end

  describe "Round-trip conversions" do
    it "weight -> volume -> weight maintains original weight" do
      original_weight = Unit::Weight.new(500, :gram)
      density = Unit::Density.new(1.0, :gram_per_milliliter)

      volume = original_weight.to_volume(density)
      final_weight = volume.to_weight(density)

      final_weight.value.should be_close(original_weight.value, BigDecimal.new("0.001"))
    end

    it "volume -> weight -> volume maintains original volume" do
      original_volume = Unit::Volume.new(500, :milliliter)
      density = Unit::Density.new(1.0, :gram_per_milliliter)

      weight = original_volume.to_weight(density)
      final_volume = weight.to_volume(density)

      final_volume.value.should be_close(original_volume.value, BigDecimal.new("0.001"))
    end
  end

  describe "Explicit naming methods" do
    it "volume_given works same as to_volume" do
      weight = Unit::Weight.new(500, :gram)
      density = Unit::Density.new(1.0, :gram_per_milliliter)

      volume1 = weight.to_volume(density)
      volume2 = weight.volume_given(density)

      volume1.should eq(volume2)
    end

    it "volume_given overload works" do
      weight = Unit::Weight.new(500, :gram)

      volume1 = weight.to_volume(1.0, :gram_per_milliliter)
      volume2 = weight.volume_given(1.0, :gram_per_milliliter)

      volume1.should eq(volume2)
    end

    it "weight_given works same as to_weight" do
      volume = Unit::Volume.new(500, :milliliter)
      density = Unit::Density.new(1.0, :gram_per_milliliter)

      weight1 = volume.to_weight(density)
      weight2 = volume.weight_given(density)

      weight1.should eq(weight2)
    end

    it "weight_given overload works" do
      volume = Unit::Volume.new(500, :milliliter)

      weight1 = volume.to_weight(1.0, :gram_per_milliliter)
      weight2 = volume.weight_given(1.0, :gram_per_milliliter)

      weight1.should eq(weight2)
    end
  end

  describe "Real-world examples" do
    it "calculates baking conversions" do
      # 200g of flour to volume using flour density
      flour_weight = Unit::Weight.new(200, :gram)
      flour_density = Unit::Density.new(0.593, :gram_per_milliliter)
      flour_volume = flour_weight.to_volume(flour_density)

      # Should be approximately 337 mL
      flour_volume.value.should be_close(BigDecimal.new("337.27"), BigDecimal.new("0.01"))
      flour_volume.unit.should eq(Unit::Volume::Unit::Milliliter)

      # Convert to cups for recipe
      flour_in_cups = flour_volume.convert_to(:cup)
      flour_in_cups.value.should be_close(BigDecimal.new("1.425"), BigDecimal.new("0.001"))
    end

    it "calculates liquid conversions" do
      # 250mL of milk to weight
      milk_volume = Unit::Volume.new(250, :milliliter)
      milk_density = Unit::Density.new(1.030, :gram_per_milliliter)
      milk_weight = milk_volume.to_weight(milk_density)

      # Should be approximately 258g
      milk_weight.value.should be_close(BigDecimal.new("257.5"), BigDecimal.new("0.1"))
      milk_weight.unit.should eq(Unit::Weight::Unit::Gram)

      # Convert to pounds
      milk_in_pounds = milk_weight.convert_to(:pound)
      milk_in_pounds.value.should be_close(BigDecimal.new("0.567"), BigDecimal.new("0.001"))
    end

    it "handles scientific calculations" do
      # Mercury density calculation
      mercury_volume = Unit::Volume.new(100, :milliliter)
      mercury_density = Unit::Density.new(13.534, :gram_per_cubic_centimeter)
      mercury_weight = mercury_volume.to_weight(mercury_density)

      # Mercury density = 13.534 g/cm³ = 13.534 g/mL
      # Weight = 100 mL * 13.534 g/mL = 1353.4 g = 1.3534 kg
      mercury_weight.value.should be_close(BigDecimal.new("1353.4"), BigDecimal.new("0.1"))
      mercury_weight.unit.should eq(Unit::Weight::Unit::Gram)

      # Convert to kilograms
      mercury_in_kg = mercury_weight.convert_to(:kilogram)
      mercury_in_kg.value.should be_close(BigDecimal.new("1.3534"), BigDecimal.new("0.0001"))
    end
  end
end
