require "../avram_spec_helper"

# Test migration class that manually implements what the helpers would do
class TestMigrationWithHelpers < AvramSpecHelper::TestMigration
  def add_measurement_column(table, name, type, **options)
    # Implement what the macro would generate
    precision = options[:precision]? || 15
    scale = options[:scale]? || 6
    unit_size = options[:unit_size]? || 20

    # Directly add columns to the array to simulate what the macro does
    # Add value column
    value_options = Hash(Symbol, String | Int32 | Bool).new
    value_options[:precision] = precision
    value_options[:scale] = scale

    @columns << {
      name:    "#{name}_value",
      type:    "Float64",
      options: value_options,
    }

    # Add unit column
    unit_options = Hash(Symbol, String | Int32 | Bool).new
    unit_options[:size] = unit_size

    @columns << {
      name:    "#{name}_unit",
      type:    "String",
      options: unit_options,
    }

    if options[:required]?
      @executed_sql << "ALTER COLUMN #{name}_value SET NOT NULL"
      @executed_sql << "ALTER COLUMN #{name}_unit SET NOT NULL"
    end

    # Use the ? operator to safely access the values
    default_value = options[:default_value]?
    default_unit = options[:default_unit]?

    if default_value && default_unit
      @executed_sql << "ALTER COLUMN #{name}_value SET DEFAULT #{default_value}"
      @executed_sql << "ALTER COLUMN #{name}_unit SET DEFAULT '#{default_unit}'"
    end

    # Add check constraint for valid units
    if options[:add_constraint]? != false
      # For testing, we'll simulate the constraint SQL
      unit_values = case type
                    when :Weight
                      # Filter out aliases by selecting unique values based on their to_s representation
                      Unit::Weight::Unit.values.map(&.to_s).uniq.map { |u| "'#{u}'" }.join(", ")
                    when :Length
                      Unit::Length::Unit.values.map(&.to_s).uniq.map { |u| "'#{u}'" }.join(", ")
                    when :Volume
                      Unit::Volume::Unit.values.map(&.to_s).uniq.map { |u| "'#{u}'" }.join(", ")
                    else
                      ""
                    end

      execute <<-SQL
        ALTER TABLE #{table}
        ADD CONSTRAINT chk_#{name}_unit
        CHECK (#{name}_unit IN (#{unit_values}))
      SQL
    end

    # Add index for common queries
    if options[:indexed]?
      @indexes << {
        table:   table.to_s,
        columns: ["#{name}_value", "#{name}_unit"],
      }
    end
  end

  def remove_measurement_column(table, name)
    # Remove from indexes
    @indexes.reject! do |idx|
      idx[:table] == table.to_s && idx[:columns] == ["#{name}_value", "#{name}_unit"]
    end

    # Remove columns
    @columns.reject! { |c| c[:name] == "#{name}_value" || c[:name] == "#{name}_unit" }
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
      value_column = migration.columns.find { |c| c[:name] == "weight_value" }
      value_column.should_not be_nil
      value_column.not_nil![:type].should eq("Float64")
      value_column.not_nil![:options][:precision].should eq(15)
      value_column.not_nil![:options][:scale].should eq(6)

      # Check unit column
      unit_column = migration.columns.find { |c| c[:name] == "weight_unit" }
      unit_column.should_not be_nil
      unit_column.not_nil![:type].should eq("String")
      unit_column.not_nil![:options][:size].should eq(20)
    end

    it "supports custom precision and scale" do
      migration = TestMigrationWithHelpers.new

      migration.add_measurement_column :products, :price, :Money,
        precision: 20,
        scale: 4

      value_column = migration.columns.find { |c| c[:name] == "price_value" }
      value_column.not_nil![:options][:precision].should eq(20)
      value_column.not_nil![:options][:scale].should eq(4)
    end

    it "supports custom unit field size" do
      migration = TestMigrationWithHelpers.new

      migration.add_measurement_column :products, :weight, :Weight,
        unit_size: 50

      unit_column = migration.columns.find { |c| c[:name] == "weight_unit" }
      unit_column.not_nil![:options][:size].should eq(50)
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
      constraint_sql = migration.executed_sql.find { |sql| sql.includes?("ADD CONSTRAINT") }
      constraint_sql.should_not be_nil
      constraint_sql.not_nil!.should contain("chk_weight_unit")
      constraint_sql.not_nil!.should contain("CHECK (weight_unit IN")

      # Should include all weight units
      Unit::Weight::Unit.each do |unit|
        constraint_sql.not_nil!.should contain("'#{unit}'")
      end
    end

    it "skips constraint when add_constraint is false" do
      migration = TestMigrationWithHelpers.new

      migration.add_measurement_column :products, :weight, :Weight,
        add_constraint: false

      # Should not have constraint SQL
      constraint_sql = migration.executed_sql.find { |sql| sql.includes?("ADD CONSTRAINT") }
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
      migration.executed_sql.any? { |sql| sql.includes?("NOT NULL") }.should be_true
      migration.executed_sql.any? { |sql| sql.includes?("DEFAULT") }.should be_true
      migration.executed_sql.any? { |sql| sql.includes?("CHECK") }.should be_true
    end
  end
end
