require "../avram_spec_helper"

describe Unit::Avram do
  describe "MeasurementType subclasses" do
    describe Unit::Avram::WeightType do
      describe ".parse" do
        it "parses valid JSON into a Weight measurement" do
          json = %q({"value": "10.5", "unit": "kilogram"})
          result = Unit::Avram::WeightType.parse(json)

          result.should be_a(Avram::Type::SuccessfulCast(Unit::Weight))
          weight = result.as(Avram::Type::SuccessfulCast(Unit::Weight)).value
          weight.value.should eq(BigDecimal.new("10.5"))
          weight.unit.should eq(Unit::Weight::Unit::Kilogram)
        end

        it "returns SuccessfulCast(Nil) for blank values" do
          result = Unit::Avram::WeightType.parse("")
          result.should be_a(Avram::Type::SuccessfulCast(Nil))
          result.value.should be_nil

          result2 = Unit::Avram::WeightType.parse("   ")
          result2.should be_a(Avram::Type::SuccessfulCast(Nil))
          result2.value.should be_nil
        end

        it "returns FailedCast for invalid JSON" do
          result = Unit::Avram::WeightType.parse("not json")
          result.should be_a(Avram::Type::FailedCast)
        end

        it "returns FailedCast for invalid unit" do
          json = %q({"value": "10.5", "unit": "invalid_unit"})
          result = Unit::Avram::WeightType.parse(json)
          result.should be_a(Avram::Type::FailedCast)
        end
      end

      describe ".to_db" do
        it "serializes a Weight measurement to JSON" do
          weight = Unit::Weight.new(25.5, :kilogram)
          json = Unit::Avram::WeightType.to_db(weight)

          parsed = JSON.parse(json)
          parsed["value"].should eq("25.5")
          parsed["unit"].should eq("kilogram")
        end

        it "returns nil for nil value" do
          Unit::Avram::WeightType.to_db(nil).should be_nil
        end
      end
    end

    describe Unit::Avram::LengthType do
      describe ".parse" do
        it "parses valid JSON into a Length measurement" do
          json = %q({"value": "100", "unit": "meter"})
          result = Unit::Avram::LengthType.parse(json)

          result.should be_a(Avram::Type::SuccessfulCast(Unit::Length))
          length = result.as(Avram::Type::SuccessfulCast(Unit::Length)).value
          length.value.should eq(BigDecimal.new("100"))
          length.unit.should eq(Unit::Length::Unit::Meter)
        end

        it "handles different length units" do
          json = %q({"value": "5.5", "unit": "inch"})
          result = Unit::Avram::LengthType.parse(json)

          result.should be_a(Avram::Type::SuccessfulCast(Unit::Length))
          length = result.as(Avram::Type::SuccessfulCast(Unit::Length)).value
          length.unit.should eq(Unit::Length::Unit::Inch)
        end
      end

      describe ".to_db" do
        it "serializes a Length measurement to JSON" do
          length = Unit::Length.new(2.5, :meter)
          json = Unit::Avram::LengthType.to_db(length)

          parsed = JSON.parse(json)
          parsed["value"].should eq("2.5")
          parsed["unit"].should eq("meter")
        end
      end
    end

    describe Unit::Avram::VolumeType do
      describe ".parse" do
        it "parses valid JSON into a Volume measurement" do
          json = %q({"value": "3.5", "unit": "liter"})
          result = Unit::Avram::VolumeType.parse(json)

          result.should be_a(Avram::Type::SuccessfulCast(Unit::Volume))
          volume = result.as(Avram::Type::SuccessfulCast(Unit::Volume)).value
          volume.value.should eq(BigDecimal.new("3.5"))
          volume.unit.should eq(Unit::Volume::Unit::Liter)
        end
      end

      describe ".to_db" do
        it "serializes a Volume measurement to JSON" do
          volume = Unit::Volume.new(1.5, :gallon)
          json = Unit::Avram::VolumeType.to_db(volume)

          parsed = JSON.parse(json)
          parsed["value"].should eq("1.5")
          parsed["unit"].should eq("gallon")
        end
      end
    end

    describe "edge cases" do
      it "handles very large numbers" do
        json = %q({"value": "999999999999999.999999", "unit": "kilogram"})
        result = Unit::Avram::WeightType.parse(json)

        result.should be_a(Avram::Type::SuccessfulCast(Unit::Weight))
        weight = result.as(Avram::Type::SuccessfulCast(Unit::Weight)).value
        weight.value.should eq(BigDecimal.new("999999999999999.999999"))
      end

      it "handles very small numbers" do
        json = %q({"value": "0.000000000001", "unit": "gram"})
        result = Unit::Avram::WeightType.parse(json)

        result.should be_a(Avram::Type::SuccessfulCast(Unit::Weight))
        weight = result.as(Avram::Type::SuccessfulCast(Unit::Weight)).value
        weight.value.should eq(BigDecimal.new("0.000000000001"))
      end

      it "handles negative numbers" do
        # Weight doesn't typically have negative values, but the type should handle them
        json = %q({"value": "-10", "unit": "kilogram"})
        result = Unit::Avram::WeightType.parse(json)

        result.should be_a(Avram::Type::SuccessfulCast(Unit::Weight))
        weight = result.as(Avram::Type::SuccessfulCast(Unit::Weight)).value
        weight.value.should eq(BigDecimal.new("-10"))
      end
    end
  end
end
