require "avram"
require "json"

module Unit
  module Avram
    # Macro to generate Avram type modules for measurements
    macro define_measurement_type(name, measurement_class)
      module {{name}}Type
        alias ColumnType = String
        include ::Avram::Type

        def self.criteria(query : T, column) forall T
          ::Avram::Criteria(T, String).new(query, column)
        end

        def from_db!(value : String)
          parse!(value)
        end

        def parse(value : String)
          return SuccessfulCast(Nil).new(nil) if value.blank?

          parsed = JSON.parse(value)
          # Unit.parse expects lowercase unit names
          unit_str = parsed["unit"].as_s
          measurement = {{measurement_class}}.new(
            BigDecimal.new(parsed["value"].as_s),
            {{measurement_class}}::Unit.parse(unit_str)
          )
          SuccessfulCast({{measurement_class}}).new(measurement)
        rescue JSON::ParseException | ArgumentError
          FailedCast.new
        end

        def parse(value : {{measurement_class}})
          SuccessfulCast({{measurement_class}}).new(value)
        end

        def parse(value : Nil)
          SuccessfulCast(Nil).new(nil)
        end

        def to_db(value : {{measurement_class}})
          {
            value: value.value.to_s,
            unit: value.unit.to_s.downcase
          }.to_json
        end

        def to_db(value : Nil)
          nil
        end
      end
    end

    # Define all measurement types using the macro
    define_measurement_type Weight, Unit::Weight
    define_measurement_type Length, Unit::Length
    define_measurement_type Volume, Unit::Volume

    # Column extensions for easy measurement column definition
    module ColumnExtensions
      # Macro to define measurement columns using composite pattern
      macro measurement_column(name, type, *, required = false, indexed = false, default_unit = nil)
        # Store value and unit separately for better indexing
        column {{name.id}}_value : Float64{% unless required %}?{% end %}
        column {{name.id}}_unit : String{% unless required %}?{% end %}
      end

      # This macro should be called at the model level, not inside table block
      macro define_measurement_accessors(name, type, *, required = false)
        # Virtual attribute for the measurement object
        @[JSON::Field(ignore: true)]
        @_{{name}}_measurement : Unit::{{type.id}}{% unless required %}?{% end %}

        def {{name}} : Unit::{{type.id}}{% unless required %}?{% end %}
          return @_{{name}}_measurement if @_{{name}}_measurement

          value = {{name}}_value
          unit_str = {{name}}_unit

          {% if required %}
            @_{{name}}_measurement = Unit::{{type.id}}.new(
              value,
              Unit::{{type.id}}::Unit.parse(unit_str)
            )
          {% else %}
            return nil if value.nil? || unit_str.nil?

            @_{{name}}_measurement = Unit::{{type.id}}.new(
              value,
              Unit::{{type.id}}::Unit.parse(unit_str)
            )
          {% end %}
        end

        def {{name}}=(measurement : Unit::{{type.id}}{% unless required %}?{% end %})
          @_{{name}}_measurement = measurement

          {% if required %}
            self.{{name}}_value = measurement.value.to_f
            self.{{name}}_unit = measurement.unit.to_s.downcase
          {% else %}
            if measurement
              self.{{name}}_value = measurement.value.to_f
              self.{{name}}_unit = measurement.unit.to_s.downcase
            else
              self.{{name}}_value = nil
              self.{{name}}_unit = nil
            end
          {% end %}
        end

        # Helper methods for unit conversion
        def {{name}}_in(unit : Unit::{{type.id}}::Unit) : BigDecimal?
          {{name}}.try(&.convert_to(unit).value)
        end

        # Setter with automatic parsing
        def {{name}}_from_string=(value : String)
          self.{{name}} = Unit::Parser.parse(Unit::{{type.id}}, value)
        end
      end
    end

    # Query extensions for measurement operations
    module QueryExtensions
      macro measurement_query_methods(column_name, type)
        # Find records where measurement is greater than a value
        def with_{{column_name}}_greater_than(measurement : Unit::{{type.id}})
          normalized_value = measurement.convert_to(measurement.class.base_unit).value

          # Build a CASE expression for unit conversion at the database level
          case_expr = String.build do |str|
            str << "({{column_name}}_value * CASE {{column_name}}_unit"
            Unit::{{type.id}}::Unit.each do |unit|
              conversion_factor = Unit::{{type.id}}.new(1, unit).convert_to(Unit::{{type.id}}.base_unit).value
              str << " WHEN '#{unit.to_s.downcase}' THEN #{conversion_factor}"
            end
            str << " END)"
          end

          where("#{case_expr} > ?", normalized_value)
        end

        # Find records where measurement is less than a value
        def with_{{column_name}}_less_than(measurement : Unit::{{type.id}})
          normalized_value = measurement.convert_to(measurement.class.base_unit).value

          case_expr = String.build do |str|
            str << "({{column_name}}_value * CASE {{column_name}}_unit"
            Unit::{{type.id}}::Unit.each do |unit|
              conversion_factor = Unit::{{type.id}}.new(1, unit).convert_to(Unit::{{type.id}}.base_unit).value
              str << " WHEN '#{unit.to_s.downcase}' THEN #{conversion_factor}"
            end
            str << " END)"
          end

          where("#{case_expr} < ?", normalized_value)
        end

        # Find records within a range
        def with_{{column_name}}_between(min : Unit::{{type.id}}, max : Unit::{{type.id}})
          min_normalized = min.convert_to(min.class.base_unit).value
          max_normalized = max.convert_to(max.class.base_unit).value

          case_expr = String.build do |str|
            str << "({{column_name}}_value * CASE {{column_name}}_unit"
            Unit::{{type.id}}::Unit.each do |unit|
              conversion_factor = Unit::{{type.id}}.new(1, unit).convert_to(Unit::{{type.id}}.base_unit).value
              str << " WHEN '#{unit.to_s.downcase}' THEN #{conversion_factor}"
            end
            str << " END)"
          end

          where("#{case_expr} BETWEEN ? AND ?", min_normalized, max_normalized)
        end

        # Find by specific unit
        def with_{{column_name}}_unit(unit : Unit::{{type.id}}::Unit)
          where({{column_name}}_unit: unit.to_s.downcase)
        end
      end
    end

    # Validation extensions for measurements
    module ValidationExtensions
      macro validate_measurement_range(column, min, max, message = nil)
        validate_required {{column}}

        before_save do
          if (measurement = {{column}}.value)
            min_value = {{min}}.convert_to(measurement.unit).value
            max_value = {{max}}.convert_to(measurement.unit).value

            if measurement.value < min_value || measurement.value > max_value
              error_msg = {{message}} || "must be between #{{{min}}} and #{{{max}}}"
              {{column}}.add_error(error_msg)
            end
          end
        end
      end

      macro validate_measurement_positive(column, message = nil)
        before_save do
          if (measurement = {{column}}.value)
            if measurement.value <= 0
              error_msg = {{message}} || "must be positive"
              {{column}}.add_error(error_msg)
            end
          end
        end
      end

      macro validate_measurement_unit(column, allowed_units, message = nil)
        before_save do
          if (measurement = {{column}}.value)
            unless {{allowed_units}}.includes?(measurement.unit)
              error_msg = {{message}} || "unit must be one of: #{{{allowed_units}}.join(", ")}"
              {{column}}.add_error(error_msg)
            end
          end
        end
      end
    end

    # Migration helpers for creating measurement columns with PostgreSQL optimizations
    module MigrationHelpers
      macro add_measurement_column(table, name, type, **options)
        # Use NUMERIC for better precision with measurements in PostgreSQL
        add :{{name}}_value, "NUMERIC(#{{{options[:precision] || 20}}}, #{{{options[:scale] || 10}}})"
        add :{{name}}_unit, String, size: {{options[:unit_size] || 20}}

        {% if options[:required] %}
          change_null :{{name}}_value, false
          change_null :{{name}}_unit, false
        {% end %}

        {% if options[:default_value] && options[:default_unit] %}
          change_default :{{name}}_value, {{options[:default_value]}}
          change_default :{{name}}_unit, {{options[:default_unit].stringify}}
        {% end %}

        # Add enum type for better performance and validation
        {% if options[:create_enum] != false %}
          execute <<-SQL
            DO $$ BEGIN
              CREATE TYPE {{name}}_unit_enum AS ENUM (
                #{Unit::{{type.id}}::Unit.values.map(&.to_s).uniq.map { |u| "'#{u}'" }.join(", ")}
              );
            EXCEPTION
              WHEN duplicate_object THEN null;
            END $$;
          SQL

          # Change column to use enum type
          execute <<-SQL
            ALTER TABLE {{table}}
            ALTER COLUMN {{name}}_unit TYPE {{name}}_unit_enum
            USING {{name}}_unit::{{name}}_unit_enum
          SQL
        {% else %}
          # Just add check constraint
          execute <<-SQL
            ALTER TABLE {{table}}
            ADD CONSTRAINT chk_{{name}}_unit
            CHECK ({{name}}_unit IN (
              #{Unit::{{type.id}}::Unit.values.map(&.to_s).uniq.map { |u| "'#{u}'" }.join(", ")}
            ))
          SQL
        {% end %}

        # Add composite index for range queries
        {% if options[:indexed] %}
          add_index :{{table}}, [:{{name}}_value, :{{name}}_unit]

          # Add GiST index for range queries if requested
          {% if options[:gist_index] %}
            execute <<-SQL
              CREATE INDEX idx_{{table}}_{{name}}_range
              ON {{table}}
              USING gist (
                numrange(
                  {{name}}_value::numeric,
                  {{name}}_value::numeric,
                  '[]'
                )
              )
            SQL
          {% end %}
        {% end %}

        # Add generated column for normalized value if requested
        {% if options[:add_normalized_column] %}
          execute <<-SQL
            ALTER TABLE {{table}}
            ADD COLUMN {{name}}_normalized NUMERIC GENERATED ALWAYS AS (
              {{name}}_value * CASE {{name}}_unit
                #{generate_unit_conversion_cases(type)}
              END
            ) STORED
          SQL

          # Index the normalized column for fast queries
          add_index :{{table}}, :{{name}}_normalized
        {% end %}
      end

      macro remove_measurement_column(table, name)
        remove_index :{{table}}, [:{{name}}_value, :{{name}}_unit]
        remove :{{name}}_value
        remove :{{name}}_unit
      end

      # Helper to generate CASE statements for unit conversion
      private macro generate_unit_conversion_cases(type)
        String.build do |str|
          Unit::{{type.id}}::Unit.each do |unit|
            factor = Unit::{{type.id}}.new(1, unit).convert_to(Unit::{{type.id}}.base_unit).value
            str << "WHEN '#{unit}' THEN #{factor} "
          end
        end
      end

      # Add a function for measurement aggregation
      macro create_measurement_aggregation_function(type)
        execute <<-SQL
          CREATE OR REPLACE FUNCTION sum_{{type.downcase}}_measurements(
            values NUMERIC[],
            units TEXT[],
            target_unit TEXT
          ) RETURNS NUMERIC AS $$
          DECLARE
            total NUMERIC := 0;
            i INTEGER;
            conversion_factor NUMERIC;
          BEGIN
            FOR i IN 1..array_length(values, 1) LOOP
              conversion_factor := CASE units[i]
                #{generate_unit_conversion_cases(type)}
                ELSE 1
              END;

              total := total + (values[i] * conversion_factor);
            END LOOP;

            -- Convert from base unit to target unit
            conversion_factor := CASE target_unit
              #{generate_unit_conversion_cases(type)}
              ELSE 1
            END;

            RETURN total / conversion_factor;
          END;
          $$ LANGUAGE plpgsql IMMUTABLE;
        SQL
      end

      # PostgreSQL-specific query extensions
      module PostgreSQLExtensions
        # Use PostgreSQL's numeric operations for better precision
        macro measurement_sum(column_name, type, target_unit)
        select_append <<-SQL
          sum_{{type.downcase}}_measurements(
            array_agg({{column_name}}_value),
            array_agg({{column_name}}_unit),
            '#{{{target_unit}}}'
          ) AS {{column_name}}_sum
        SQL
      end

        # Average with proper unit handling
        macro measurement_avg(column_name, type, target_unit)
        select_append <<-SQL
          sum_{{type.downcase}}_measurements(
            array_agg({{column_name}}_value),
            array_agg({{column_name}}_unit),
            '#{{{target_unit}}}'
          ) / COUNT(*) AS {{column_name}}_avg
        SQL
      end

        # Use normalized column if available for faster queries
        macro with_normalized_greater_than(column_name, measurement)
        normalized_value = {{measurement}}.convert_to({{measurement}}.class.base_unit).value
        where("{{column_name}}_normalized > ?", normalized_value)
      end

        macro with_normalized_between(column_name, min, max)
        min_normalized = {{min}}.convert_to({{min}}.class.base_unit).value
        max_normalized = {{max}}.convert_to({{max}}.class.base_unit).value
        where("{{column_name}}_normalized BETWEEN ? AND ?", min_normalized, max_normalized)
      end
      end

      # JSONB storage type for flexible measurement storage
      module MeasurementJSONBType
        include ::Avram::Type
        alias ColumnType = JSON::Any

        def self.criteria(query : T, column) forall T
          ::Avram::Criteria(T, JSON::Any).new(query, column)
        end

        def parse(value : JSON::Any)
          return SuccessfulCast(Nil).new(nil) if value.nil?

          # Determine measurement type from stored type field
          measurement_type = value["type"].as_s
          parsed_value = BigDecimal.new(value["value"].as_s)
          unit_str = value["unit"].as_s

          measurement = case measurement_type
                        when "Weight"
                          Unit::Weight.new(parsed_value, Unit::Weight::Unit.parse(unit_str))
                        when "Length"
                          Unit::Length.new(parsed_value, Unit::Length::Unit.parse(unit_str))
                        when "Volume"
                          Unit::Volume.new(parsed_value, Unit::Volume::Unit.parse(unit_str))
                        else
                          return FailedCast.new
                        end

          # Return the correct type based on what was parsed
          case measurement
          when Unit::Weight
            SuccessfulCast(Unit::Weight).new(measurement)
          when Unit::Length
            SuccessfulCast(Unit::Length).new(measurement)
          when Unit::Volume
            SuccessfulCast(Unit::Volume).new(measurement)
          else
            FailedCast.new
          end
        rescue
          FailedCast.new
        end

        def to_db(value : Unit::Measurement) : JSON::Any
          JSON::Any.new({
            "type"       => value.class.name.split("::").last,
            "value"      => value.value.to_s,
            "unit"       => value.unit.to_s.downcase,
            "normalized" => value.convert_to(value.class.base_unit).value.to_s,
          })
        end

        def to_db(value : Nil)
          nil
        end

        def from_db!(value : JSON::Any)
          parse!(value)
        end
      end
    end
  end
end
