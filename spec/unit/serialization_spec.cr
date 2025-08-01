require "../spec_helper"
require "json"
require "yaml"

describe "Serialization" do
  describe "JSON Serialization" do
    it "serializes and deserializes Weight measurements" do
      weight = Unit::Weight.new(100.5, :gram)
      json = weight.to_json

      # Verify JSON structure
      parsed = JSON.parse(json)
      parsed["value"].as_s.should eq("100.5")
      parsed["unit"].as_s.should eq("Gram")

      # Round-trip test
      deserialized = Unit::Weight.from_json(json)
      deserialized.value.should eq(weight.value)
      deserialized.unit.should eq(weight.unit)
    end

    it "serializes and deserializes Length measurements" do
      length = Unit::Length.new(42.195, :kilometer)
      json = length.to_json

      # Round-trip test
      deserialized = Unit::Length.from_json(json)
      deserialized.value.should eq(length.value)
      deserialized.unit.should eq(length.unit)
    end

    it "preserves BigDecimal precision" do
      # Very large number
      weight = Unit::Weight.new(BigDecimal.new("123456789012345678901234567890.123456789"), :kilogram)
      json = weight.to_json
      deserialized = Unit::Weight.from_json(json)
      # Compare values, not string representation (which may use scientific notation)
      deserialized.value.should eq(BigDecimal.new("123456789012345678901234567890.123456789"))

      # Very small number
      length = Unit::Length.new(BigDecimal.new("0.000000000000000000000000000001"), :meter)
      json2 = length.to_json
      deserialized2 = Unit::Length.from_json(json2)
      deserialized2.value.should eq(BigDecimal.new("0.000000000000000000000000000001"))
    end

    it "handles case-insensitive enum parsing" do
      # Lowercase
      json1 = %q({"value": "100", "unit": "gram"})
      weight1 = Unit::Weight.from_json(json1)
      weight1.unit.should eq(Unit::Weight::Unit::Gram)

      # Uppercase
      json2 = %q({"value": "100", "unit": "KILOGRAM"})
      weight2 = Unit::Weight.from_json(json2)
      weight2.unit.should eq(Unit::Weight::Unit::Kilogram)

      # Mixed case
      json3 = %q({"value": "100", "unit": "MeTer"})
      length = Unit::Length.from_json(json3)
      length.unit.should eq(Unit::Length::Unit::Meter)
    end

    it "raises error for invalid JSON" do
      # Invalid JSON structure
      expect_raises(JSON::ParseException) do
        Unit::Weight.from_json(%q({"invalid": "structure"}))
      end

      # Invalid unit value
      expect_raises(JSON::ParseException) do
        Unit::Weight.from_json(%q({"value": "100", "unit": "invalid_unit"}))
      end

      # Invalid decimal value
      expect_raises(InvalidBigDecimalException) do
        Unit::Weight.from_json(%q({"value": "not_a_number", "unit": "gram"}))
      end
    end

    it "works with arrays of measurements" do
      weights = [
        Unit::Weight.new(100, :gram),
        Unit::Weight.new(2.5, :kilogram),
        Unit::Weight.new(0.5, :pound),
      ]

      json = weights.to_json

      # Parse JSON array manually since we don't use JSON::Serializable
      parsed = JSON.parse(json)
      deserialized = parsed.as_a.map do |item|
        Unit::Weight.from_json(item.to_json)
      end

      deserialized.size.should eq(3)
      deserialized[0].value.should eq(100)
      deserialized[0].unit.should eq(Unit::Weight::Unit::Gram)
      deserialized[1].value.should eq(2.5)
      deserialized[1].unit.should eq(Unit::Weight::Unit::Kilogram)
      deserialized[2].value.should eq(0.5)
      deserialized[2].unit.should eq(Unit::Weight::Unit::Pound)
    end
  end

  describe "YAML Serialization" do
    it "serializes and deserializes Weight measurements" do
      weight = Unit::Weight.new(100.5, :gram)
      yaml = weight.to_yaml

      # Verify YAML structure
      yaml.should contain("value: 100.5")
      yaml.should contain("unit: Gram")

      # Round-trip test
      deserialized = Unit::Weight.from_yaml(yaml)
      deserialized.value.should eq(weight.value)
      deserialized.unit.should eq(weight.unit)
    end

    it "serializes and deserializes Volume measurements" do
      volume = Unit::Volume.new(25.5, :liter)
      yaml = volume.to_yaml

      # Round-trip test
      deserialized = Unit::Volume.from_yaml(yaml)
      deserialized.value.should eq(volume.value)
      deserialized.unit.should eq(volume.unit)
    end

    it "preserves BigDecimal precision in YAML" do
      # Scientific notation
      weight = Unit::Weight.new(BigDecimal.new("1.23456789e100"), :kilogram)
      yaml = weight.to_yaml
      deserialized = Unit::Weight.from_yaml(yaml)
      deserialized.value.should eq(weight.value)
    end

    it "handles case-insensitive enum parsing in YAML" do
      # Lowercase
      yaml1 = "---\nvalue: 100\nunit: gram\n"
      weight1 = Unit::Weight.from_yaml(yaml1)
      weight1.unit.should eq(Unit::Weight::Unit::Gram)

      # Uppercase
      yaml2 = "---\nvalue: 100\nunit: POUND\n"
      weight2 = Unit::Weight.from_yaml(yaml2)
      weight2.unit.should eq(Unit::Weight::Unit::Pound)
    end

    it "raises error for invalid YAML" do
      # Invalid unit value
      expect_raises(YAML::ParseException) do
        Unit::Weight.from_yaml("---\nvalue: 100\nunit: not_a_unit\n")
      end

      # Invalid decimal value
      expect_raises(InvalidBigDecimalException) do
        Unit::Weight.from_yaml("---\nvalue: \"abc\"\nunit: gram\n")
      end
    end

    it "works with hashes of measurements" do
      measurements = {
        "weight" => Unit::Weight.new(75, :kilogram),
        "height" => Unit::Length.new(180, :centimeter),
      }

      yaml = measurements.to_yaml

      # Deserialize as separate types
      parsed = YAML.parse(yaml)
      weight_data = parsed["weight"]
      weight = Unit::Weight.from_yaml(weight_data.to_yaml)
      weight.value.should eq(75)
      weight.unit.should eq(Unit::Weight::Unit::Kilogram)

      height_data = parsed["height"]
      height = Unit::Length.from_yaml(height_data.to_yaml)
      height.value.should eq(180)
      height.unit.should eq(Unit::Length::Unit::Centimeter)
    end
  end

  describe "Cross-format compatibility" do
    it "can serialize to JSON and deserialize from equivalent YAML" do
      weight = Unit::Weight.new(50, :kilogram)

      # Create equivalent YAML manually
      yaml = "---\nvalue: 50\nunit: Kilogram\n"
      from_yaml = Unit::Weight.from_yaml(yaml)

      from_yaml.value.should eq(weight.value)
      from_yaml.unit.should eq(weight.unit)
    end
  end

  describe "Different numeric types" do
    it "serializes measurements created from different numeric types" do
      # From Int32
      w1 = Unit::Weight.new(100_i32, :gram)
      json1 = w1.to_json
      Unit::Weight.from_json(json1).value.should eq(100)

      # From Float64
      w2 = Unit::Weight.new(99.99_f64, :gram)
      json2 = w2.to_json
      Unit::Weight.from_json(json2).value.should eq(BigDecimal.new("99.99"))

      # From BigDecimal
      w3 = Unit::Weight.new(BigDecimal.new("123.456"), :gram)
      json3 = w3.to_json
      Unit::Weight.from_json(json3).value.should eq(BigDecimal.new("123.456"))
    end
  end
end
