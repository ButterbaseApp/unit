require "../avram_spec_helper_spec"

# Test migration class that manually implements what the helpers would do
class TestMigrationWithHelpers < AvramSpecHelper::TestMigration
  def add_measurement_column(table, name, type, **options)
    # Extract options with defaults
    precision = options[:precision]? || 15
    scale = options[:scale]? || 6
    unit_size = options[:unit_size]? || 20

    # Add the database columns
    add_value_column(name, precision, scale)
    add_unit_column(name, unit_size)

    # Apply constraints and defaults
    apply_required_constraints(name, options) if options[:required]?
    apply_default_values(name, options)
    add_unit_constraint(table, name, type, options) if options[:add_constraint]? != false
    add_measurement_index(table, name, options) if options[:indexed]?
  end

  private def add_value_column(name, precision, scale)
    value_options = Hash(Symbol, String | Int32 | Bool).new
    value_options[:precision] = precision
    value_options[:scale] = scale

    @columns << {
      name:    "#{name}_value",
      type:    "Float64",
      options: value_options,
    }
  end

  private def add_unit_column(name, unit_size)
    unit_options = Hash(Symbol, String | Int32 | Bool).new
    unit_options[:size] = unit_size

    @columns << {
      name:    "#{name}_unit",
      type:    "String",
      options: unit_options,
    }
  end

  private def apply_required_constraints(name, options)
    @executed_sql << "ALTER COLUMN #{name}_value SET NOT NULL"
    @executed_sql << "ALTER COLUMN #{name}_unit SET NOT NULL"
  end

  private def apply_default_values(name, options)
    default_value = options[:default_value]?
    default_unit = options[:default_unit]?

    if default_value && default_unit
      @executed_sql << "ALTER COLUMN #{name}_value SET DEFAULT #{default_value}"
      @executed_sql << "ALTER COLUMN #{name}_unit SET DEFAULT '#{default_unit}'"
    end
  end

  private def add_unit_constraint(table, name, type, options)
    # For testing, we'll simulate the constraint SQL
    unit_values = get_unit_values_for_type(type)

    execute <<-SQL
      ALTER TABLE #{table}
      ADD CONSTRAINT chk_#{name}_unit
      CHECK (#{name}_unit IN (#{unit_values}))
    SQL
  end

  private def get_unit_values_for_type(type)
    case type
    when :Weight
      Unit::Weight::Unit.values.map(&.to_s).uniq!.map { |unit_val| "'#{unit_val}'" }.join(", ")
    when :Length
      Unit::Length::Unit.values.map(&.to_s).uniq!.map { |unit_val| "'#{unit_val}'" }.join(", ")
    when :Volume
      Unit::Volume::Unit.values.map(&.to_s).uniq!.map { |unit_val| "'#{unit_val}'" }.join(", ")
    else
      ""
    end
  end

  private def add_measurement_index(table, name, options)
    @indexes << {
      table:   table.to_s,
      columns: ["#{name}_value", "#{name}_unit"],
    }
  end

  def remove_measurement_column(table, name)
    # Remove from indexes
    @indexes.reject! do |idx|
      idx[:table] == table.to_s && idx[:columns] == ["#{name}_value", "#{name}_unit"]
    end

    # Remove columns
    @columns.reject! { |col| col[:name] == "#{name}_value" || col[:name] == "#{name}_unit" }
  end
end

describe Unit::Avram::MigrationHelpers do
  describe "add_measurement_column" do
    it "creates value and unit columns" do
      migration = TestMigrationWithHelpers.new

      migration.add_measurement_column :products, :weight, :Weight

      # Should create two columns
      migration.columns.size.should eq(2)

      # Check value column
      value_column = migration.columns.find { |col| col[:name] == "weight_value" }
      value_column.should_not be_nil
      if value_column
        value_column[:type].should eq("Float64")
        value_column[:options][:precision].should eq(15)
        value_column[:options][:scale].should eq(6)
      else
        fail "Expected value_column to be non-nil"
      end

      # Check unit column
      unit_column = migration.columns.find { |col| col[:name] == "weight_unit" }
      unit_column.should_not be_nil
      if unit_column
        unit_column[:type].should eq("String")
        unit_column[:options][:size].should eq(20)
      else
        fail "Expected unit_column to be non-nil"
      end
    end

    it "supports custom precision and scale" do
      migration = TestMigrationWithHelpers.new

      migration.add_measurement_column :products, :price, :Money,
        precision: 20,
        scale: 4

      value_column = migration.columns.find { |col| col[:name] == "price_value" }
      if value_column
        value_column[:options][:precision].should eq(20)
        value_column[:options][:scale].should eq(4)
      else
        fail "Expected value_column to be non-nil"
      end
    end

    it "supports custom unit field size" do
      migration = TestMigrationWithHelpers.new

      migration.add_measurement_column :products, :weight, :Weight,
        unit_size: 50

      unit_column = migration.columns.find { |col| col[:name] == "weight_unit" }
      if unit_column
        unit_column[:options][:size].should eq(50)
      else
        fail "Expected unit_column to be non-nil"
      end
    end

    it "handles required columns" do
      migration = TestMigrationWithHelpers.new

      migration.add_measurement_column :products, :weight, :Weight,
        required: true

      # Should have SET NOT NULL commands
      migration.executed_sql.should contain("ALTER COLUMN weight_value SET NOT NULL")
      migration.executed_sql.should contain("ALTER COLUMN weight_unit SET NOT NULL")
    end

    it "sets default values when specified" do
      migration = TestMigrationWithHelpers.new

      migration.add_measurement_column :products, :weight, :Weight,
        default_value: 1.0,
        default_unit: "kilogram"

      # Should have SET DEFAULT commands
      migration.executed_sql.should contain("ALTER COLUMN weight_value SET DEFAULT 1.0")
      migration.executed_sql.should contain("ALTER COLUMN weight_unit SET DEFAULT 'kilogram'")
    end

    it "adds check constraint for valid units by default" do
      migration = TestMigrationWithHelpers.new

      migration.add_measurement_column :products, :weight, :Weight

      # Should have constraint SQL
      constraint_sql = migration.executed_sql.find(&.includes?("ADD CONSTRAINT"))
      constraint_sql.should_not be_nil
      if constraint_sql
        constraint_sql.should contain("chk_weight_unit")
        constraint_sql.should contain("CHECK (weight_unit IN")
      else
        fail "Expected constraint_sql to be non-nil"
      end

      # Should include all weight units
      Unit::Weight::Unit.each do |unit|
        if constraint_sql
          constraint_sql.should contain("'#{unit}'")
        else
          fail "Expected constraint_sql to be non-nil"
        end
      end
    end

    it "skips constraint when add_constraint is false" do
      migration = TestMigrationWithHelpers.new

      migration.add_measurement_column :products, :weight, :Weight,
        add_constraint: false

      # Should not have constraint SQL
      constraint_sql = migration.executed_sql.find(&.includes?("ADD CONSTRAINT"))
      constraint_sql.should be_nil
    end

    it "creates indexes when requested" do
      migration = TestMigrationWithHelpers.new

      migration.add_measurement_column :products, :weight, :Weight,
        indexed: true

      # Should have index
      migration.indexes.size.should eq(1)
      index = migration.indexes.first
      index[:table].should eq("products")
      index[:columns].should eq(["weight_value", "weight_unit"])
    end
  end

  describe "remove_measurement_column" do
    it "removes both value and unit columns" do
      migration = TestMigrationWithHelpers.new

      # First add columns
      migration.add_measurement_column :products, :weight, :Weight, indexed: true

      # Then remove them
      migration.remove_measurement_column :products, :weight

      # Should have no columns
      migration.columns.should be_empty

      # Should also remove index
      migration.indexes.should be_empty
    end

    it "only removes specified measurement columns" do
      migration = TestMigrationWithHelpers.new

      # Add multiple measurements
      migration.add_measurement_column :products, :weight, :Weight
      migration.add_measurement_column :products, :length, :Length

      # Remove only weight
      migration.remove_measurement_column :products, :weight

      # Should still have length columns
      migration.columns.size.should eq(2)
      migration.columns.map(&.[:name]).should contain("length_value")
      migration.columns.map(&.[:name]).should contain("length_unit")
      migration.columns.map(&.[:name]).should_not contain("weight_value")
      migration.columns.map(&.[:name]).should_not contain("weight_unit")
    end
  end

  describe "SQL generation" do
    it "generates valid ALTER TABLE statements" do
      migration = TestMigrationWithHelpers.new

      migration.add_measurement_column :products, :weight, :Weight,
        required: true,
        indexed: true,
        default_value: 0.0,
        default_unit: "kilogram"

      # Check all SQL was generated
      migration.executed_sql.any?(&.includes?("NOT NULL")).should be_true
      migration.executed_sql.any?(&.includes?("DEFAULT")).should be_true
      migration.executed_sql.any?(&.includes?("CHECK")).should be_true
    end
  end
end
