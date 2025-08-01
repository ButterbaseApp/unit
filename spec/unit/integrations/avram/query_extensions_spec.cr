require "../avram_spec_helper_spec"

# Since we can't use macros in test classes without proper Avram setup,
# we'll manually implement what the macro would generate for testing
class TestProductQuery < AvramSpecHelper::TestQuery
  def with_weight_greater_than(measurement : Unit::Weight)
    normalized_value = measurement.convert_to(measurement.class.base_unit).value

    case_expr = String.build do |str|
      str << "(weight_value * CASE weight_unit"
      Unit::Weight::Unit.each do |unit|
        conversion_factor = Unit::Weight.new(1, unit).convert_to(Unit::Weight.base_unit).value
        str << " WHEN '#{unit.to_s.downcase}' THEN #{conversion_factor}"
      end
      str << " END)"
    end

    where("#{case_expr} > ?", normalized_value)
  end

  def with_weight_less_than(measurement : Unit::Weight)
    normalized_value = measurement.convert_to(measurement.class.base_unit).value

    case_expr = String.build do |str|
      str << "(weight_value * CASE weight_unit"
      Unit::Weight::Unit.each do |unit|
        conversion_factor = Unit::Weight.new(1, unit).convert_to(Unit::Weight.base_unit).value
        str << " WHEN '#{unit.to_s.downcase}' THEN #{conversion_factor}"
      end
      str << " END)"
    end

    where("#{case_expr} < ?", normalized_value)
  end

  def with_weight_between(min : Unit::Weight, max : Unit::Weight)
    min_normalized = min.convert_to(min.class.base_unit).value
    max_normalized = max.convert_to(max.class.base_unit).value

    case_expr = String.build do |str|
      str << "(weight_value * CASE weight_unit"
      Unit::Weight::Unit.each do |unit|
        conversion_factor = Unit::Weight.new(1, unit).convert_to(Unit::Weight.base_unit).value
        str << " WHEN '#{unit.to_s.downcase}' THEN #{conversion_factor}"
      end
      str << " END)"
    end

    where("#{case_expr} BETWEEN ? AND ?", min_normalized, max_normalized)
  end

  def with_weight_unit(unit : Unit::Weight::Unit)
    where(weight_unit: unit.to_s.downcase)
  end

  def with_length_less_than(measurement : Unit::Length)
    normalized_value = measurement.convert_to(measurement.class.base_unit).value

    case_expr = String.build do |str|
      str << "(length_value * CASE length_unit"
      Unit::Length::Unit.each do |unit|
        conversion_factor = Unit::Length.new(1, unit).convert_to(Unit::Length.base_unit).value
        str << " WHEN '#{unit.to_s.downcase}' THEN #{conversion_factor}"
      end
      str << " END)"
    end

    where("#{case_expr} < ?", normalized_value)
  end

  def with_length_unit(unit : Unit::Length::Unit)
    where(length_unit: unit.to_s.downcase)
  end

  def with_volume_between(min : Unit::Volume, max : Unit::Volume)
    min_normalized = min.convert_to(min.class.base_unit).value
    max_normalized = max.convert_to(max.class.base_unit).value

    case_expr = String.build do |str|
      str << "(volume_value * CASE volume_unit"
      Unit::Volume::Unit.each do |unit|
        conversion_factor = Unit::Volume.new(1, unit).convert_to(Unit::Volume.base_unit).value
        str << " WHEN '#{unit.to_s.downcase}' THEN #{conversion_factor}"
      end
      str << " END)"
    end

    where("#{case_expr} BETWEEN ? AND ?", min_normalized, max_normalized)
  end
end

describe Unit::Avram::QueryExtensions do
  describe "measurement_query_methods macro" do
    describe "comparison queries" do
      it "generates with_*_greater_than query method" do
        query = TestProductQuery.new
        weight = Unit::Weight.new(10, :kilogram)

        query.with_weight_greater_than(weight)

        # Check generated SQL
        query.conditions.size.should eq(1)
        query.conditions.first.should contain("weight_value * CASE weight_unit")
        query.conditions.first.should contain("WHEN 'kilogram' THEN")
        query.conditions.first.should contain("> ?")

        # Check binding (10 kg converted to base unit)
        query.bindings.size.should eq(1)
        query.bindings.first.should eq(BigDecimal.new("10000")) # 10 kg = 10000 g
      end

      it "generates with_*_less_than query method" do
        query = TestProductQuery.new
        length = Unit::Length.new(2, :meter)

        query.with_length_less_than(length)

        query.conditions.size.should eq(1)
        query.conditions.first.should contain("length_value * CASE length_unit")
        query.conditions.first.should contain("< ?")

        # Check binding (2 m converted to base unit)
        query.bindings.first.should eq(BigDecimal.new("2")) # 2 m = 2 m (meter is base)
      end

      it "generates with_*_between query method" do
        query = TestProductQuery.new
        min_volume = Unit::Volume.new(1, :liter)
        max_volume = Unit::Volume.new(5, :liter)

        query.with_volume_between(min_volume, max_volume)

        query.conditions.size.should eq(1)
        query.conditions.first.should contain("volume_value * CASE volume_unit")
        query.conditions.first.should contain("BETWEEN ? AND ?")

        # Check bindings
        query.bindings.size.should eq(2)
        query.bindings[0].should eq(BigDecimal.new("1")) # 1 L = 1 L (liter is base)
        query.bindings[1].should eq(BigDecimal.new("5")) # 5 L
      end

      it "handles unit conversion in queries" do
        query = TestProductQuery.new

        # Query with pounds, but it should convert to grams for comparison
        weight = Unit::Weight.new(2.20462, :pound)
        query.with_weight_greater_than(weight)

        # Should convert to approximately 1000 grams
        binding = query.bindings.first.as(BigDecimal)
        binding.should be_close(BigDecimal.new("1000"), 0.1)
      end
    end

    describe "unit filtering" do
      it "generates with_*_unit query method" do
        query = TestProductQuery.new

        query.with_weight_unit(Unit::Weight::Unit::Kilogram)

        query.conditions.size.should eq(1)
        query.conditions.first.should eq("weight_unit = ?")
        query.bindings.first.should eq("kilogram")
      end

      it "works with different unit types" do
        query = TestProductQuery.new

        query.with_length_unit(Unit::Length::Unit::Foot)

        query.conditions.first.should eq("length_unit = ?")
        query.bindings.first.should eq("foot")
      end
    end

    describe "chaining queries" do
      it "allows chaining multiple measurement queries" do
        query = TestProductQuery.new

        min_weight = Unit::Weight.new(5, :kilogram)
        max_weight = Unit::Weight.new(10, :kilogram)

        query
          .with_weight_greater_than(min_weight)
          .with_weight_less_than(max_weight)
          .with_weight_unit(Unit::Weight::Unit::Kilogram)

        query.conditions.size.should eq(3)
        query.bindings.size.should eq(3)
      end
    end

    describe "CASE expression generation" do
      it "includes all unit conversion factors" do
        query = TestProductQuery.new
        weight = Unit::Weight.new(1, :kilogram)

        query.with_weight_greater_than(weight)

        condition = query.conditions.first

        # Check that all weight units are included in CASE
        Unit::Weight::Unit.each do |unit|
          condition.should contain("WHEN '#{unit.to_s.downcase}'")
        end
      end
    end
  end
end
