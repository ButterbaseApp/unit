---
title: Research Session
query: "Avram ORM architecture patterns and best practices for writing database integrations, including how Avram handles custom types, type mappings, database adapters, and extending functionality. Focus on the idiomatic way to add support for custom database types and conversions in Avram."
date: 8/1/2025
time: 10:18:08 AM
timestamp: 2025-08-01T16:18:08.929Z
exchanges: 1
---

# Research Session

## Initial Query

**Question:** Avram ORM architecture patterns and best practices for writing database integrations, including how Avram handles custom types, type mappings, database adapters, and extending functionality. Focus on the idiomatic way to add support for custom database types and conversions in Avram.

**Response:**

# Avram ORM Architecture Patterns and Best Practices for Database Integrations

## Overview of Avram's Architecture

Avram is Lucky Framework's ORM that follows a query builder pattern with strong type safety. It's built on Crystal's type system and macro capabilities to provide compile-time guarantees about database operations. Understanding Avram's architecture is crucial for implementing custom database types and conversions for your Unit measurement library.

Avram's core architecture revolves around several key concepts:
- **Operations** for handling data mutations
- **Queries** for building type-safe SQL queries
- **Models** representing database tables
- **Columns** with strong typing
- **Converters** for transforming data between Crystal and database representations
- **Adapters** for database-specific functionality

## Custom Type Support in Avram

### The Column Type System

Avram's column type system is built around the `Avram::Type` module. Each database column type corresponds to a Crystal type through a mapping system. The framework provides built-in types like `String`, `Int32`, `Float64`, `Time`, `UUID`, and others, but crucially allows extension through custom types.

```crystal
# Avram's internal type definition pattern
module Avram
  abstract class Type
    alias ColumnType = String | Int32 | Int64 | Float64 | Bool | Time | UUID | Array(String) | Array(Int32)
    
    getter :value
    getter :column
    
    def initialize(@value : T?, @column : Symbol)
    end
    
    abstract def to_db : ColumnType
    abstract def self.from_db(value : ColumnType) : T
  end
end
```

For your Unit library, you'll need to create custom types that can serialize measurements to and from database columns. The idiomatic approach involves creating a type class that inherits from `Avram::Type` and implements the conversion methods.

### Implementing Custom Measurement Types

Here's how you would implement a custom Avram type for your measurement system:

```crystal
module Unit
  module Avram
    # Custom type for storing measurements in the database
    class MeasurementType(T, U) < ::Avram::Type
      alias ColumnType = String # Store as JSON string
      
      def self.adapter
        ::Avram::PostgresAdapter
      end
      
      # Convert from database value to Crystal type
      def self.parse(value : String) : Unit::Measurement(T, U)?
        return nil if value.blank?
        
        parsed = JSON.parse(value)
        Unit::Measurement(T, U).new(
          value: BigDecimal.new(parsed["value"].as_s),
          unit: U.parse(parsed["unit"].as_s)
        )
      rescue JSON::ParseException
        nil
      end
      
      # Convert from Crystal type to database value
      def self.to_db(value : Unit::Measurement(T, U)?) : String?
        return nil if value.nil?
        
        {
          value: value.value.to_s,
          unit: value.unit.to_s
        }.to_json
      end
      
      # Database column definition
      def self.column_type : String
        "TEXT"
      end
    end
  end
end
```

## Type Mappings and Registration

### Registering Custom Types with Avram

Avram uses a registration system to map Crystal types to database column types. You need to register your custom types so Avram knows how to handle them:

```crystal
module Unit
  module Avram
    module TypeExtensions
      macro included
        # Register measurement types for each measurement category
        {% for measurement_type in [:Weight, :Length, :Volume] %}
          Avram.register_type(
            Unit::{{measurement_type.id}}::Measurement,
            Unit::Avram::MeasurementType(Unit::{{measurement_type.id}}, Unit::{{measurement_type.id}}::Unit)
          )
        {% end %}
      end
    end
  end
end

# Include in your Avram configuration
class AppDatabase < Avram::Database
  include Unit::Avram::TypeExtensions
end
```

### Column Macro Extensions

To make it easier to use measurement columns in models, create macro extensions:

```crystal
module Unit
  module Avram
    module ColumnExtensions
      # Macro to define measurement columns in models
      macro measurement_column(name, type, required = false)
        {% if required %}
          column {{name}} : Unit::{{type.id}}::Measurement
        {% else %}
          column {{name}} : Unit::{{type.id}}::Measurement?
        {% end %}
        
        # Add helper methods for unit conversion
        def {{name}}_in(unit : Unit::{{type.id}}::Unit) : BigDecimal?
          {{name}}.try(&.convert_to(unit).value)
        end
        
        # Add setter with automatic parsing
        def {{name}}_from_string=(value : String)
          self.{{name}} = Unit::Parser.parse(value, Unit::{{type.id}}::Measurement)
        end
      end
    end
  end
end
```

## Database Adapters and Portability

### Adapter Pattern Implementation

Avram supports multiple database adapters (PostgreSQL, MySQL, SQLite). Your custom types should work across different adapters:

```crystal
module Unit
  module Avram
    abstract class AbstractMeasurementAdapter
      abstract def column_type : String
      abstract def serialize(value : Measurement) : String
      abstract def deserialize(value : String) : Measurement?
    end
    
    class PostgresMeasurementAdapter < AbstractMeasurementAdapter
      def column_type : String
        "JSONB" # Use JSONB for better indexing
      end
      
      def serialize(value : Measurement) : String
        {
          v: value.value.to_s,
          u: value.unit.to_s,
          t: value.class.name
        }.to_json
      end
      
      def deserialize(value : String) : Measurement?
        data = JSON.parse(value)
        # Reconstruct the measurement based on type
        case data["t"].as_s
        when "Unit::Weight::Measurement"
          Unit::Weight::Measurement.new(
            BigDecimal.new(data["v"].as_s),
            Unit::Weight::Unit.parse(data["u"].as_s)
          )
        # ... handle other types
        end
      end
    end
    
    class MySQLMeasurementAdapter < AbstractMeasurementAdapter
      def column_type : String
        "JSON" # MySQL JSON type
      end
      
      # Similar implementation...
    end
  end
end
```

### Composite Column Pattern

For better performance and queryability, consider storing measurements as composite columns:

```crystal
module Unit
  module Avram
    module CompositeColumns
      macro measurement_columns(name, type, **options)
        # Store value and unit separately for better indexing
        column {{name}}_value : Float64{{options[:required] ? "" : "?"}}
        column {{name}}_unit : String{{options[:required] ? "" : "?"}}
        
        # Virtual attribute for the measurement object
        @[JSON::Field(ignore: true)]
        @[YAML::Field(ignore: true)]
        getter _{{name}}_measurement : Unit::{{type.id}}::Measurement?
        
        def {{name}} : Unit::{{type.id}}::Measurement?
          return @_{{name}}_measurement if @_{{name}}_measurement
          
          value = {{name}}_value
          unit_str = {{name}}_unit
          
          return nil if value.nil? || unit_str.nil?
          
          @_{{name}}_measurement = Unit::{{type.id}}::Measurement.new(
            value,
            Unit::{{type.id}}::Unit.parse(unit_str)
          )
        end
        
        def {{name}}=(measurement : Unit::{{type.id}}::Measurement?)
          @_{{name}}_measurement = measurement
          
          if measurement
            self.{{name}}_value = measurement.value.to_f
            self.{{name}}_unit = measurement.unit.to_s
          else
            self.{{name}}_value = nil
            self.{{name}}_unit = nil
          end
        end
      end
    end
  end
end
```

## Extending Avram Functionality

### Query Extensions for Measurements

Add query methods for measurement comparisons:

```crystal
module Unit
  module Avram
    module QueryExtensions
      macro measurement_query_methods(column_name)
        # Find records where measurement is greater than a value
        def with_{{column_name}}_greater_than(measurement : Measurement)
          base_value = measurement.to_base_unit_value
          where("({{column_name}}_value * (
            CASE {{column_name}}_unit
            {% for unit, factor in Unit::Weight::CONVERSION_FACTORS %}
              WHEN '{{unit}}' THEN {{factor}}
            {% end %}
            END
          )) > ?", base_value)
        end
        
        # Find records within a range
        def with_{{column_name}}_between(min : Measurement, max : Measurement)
          min_base = min.to_base_unit_value
          max_base = max.to_base_unit_value
          
          where("({{column_name}}_value * (
            CASE {{column_name}}_unit
            {% for unit, factor in Unit::Weight::CONVERSION_FACTORS %}
              WHEN '{{unit}}' THEN {{factor}}
            {% end %}
            END
          )) BETWEEN ? AND ?", min_base, max_base)
        end
        
        # Aggregate functions
        def sum_{{column_name}}(unit : Unit)
          select_sum("{{column_name}}_value * (
            CASE {{column_name}}_unit
            {% for unit, factor in Unit::Weight::CONVERSION_FACTORS %}
              WHEN '{{unit}}' THEN {{factor}}
            {% end %}
            END
          ) / {{Unit::Weight::CONVERSION_FACTORS[unit]}}")
        end
      end
    end
  end
end
```

### Operation Validations

Integrate measurement validations into Avram operations:

```crystal
module Unit
  module Avram
    module ValidationExtensions
      macro validate_measurement_range(column, min, max)
        validate_required {{column}}
        
        before_save do
          if (measurement = {{column}}.value)
            min_value = {{min}}.convert_to(measurement.unit).value
            max_value = {{max}}.convert_to(measurement.unit).value
            
            if measurement.value < min_value || measurement.value > max_value
              {{column}}.add_error("must be between #{{{min}}} and #{{{max}}}")
            end
          end
        end
      end
      
      macro validate_measurement_positive(column)
        before_save do
          if (measurement = {{column}}.value)
            if measurement.value <= 0
              {{column}}.add_error("must be positive")
            end
          end
        end
      end
    end
  end
end
```

## Best Practices and Patterns

### 1. Separation of Concerns

Keep your measurement logic separate from database concerns:

```crystal
# Good: Separate measurement logic from persistence
module Unit
  class Measurement
    # Pure measurement logic
  end
  
  module Avram
    class MeasurementType
      # Only database serialization logic
    end
  end
end
```

### 2. Migration Helpers Implementation

Based on Task 13, here's the complete migration helper implementation:

```crystal
module Unit
  module Avram
    module MigrationHelpers
      # Helper to add measurement columns with proper constraints
      macro add_measurement_column(table, name, type, **options)
        add :{{name}}_value, :float, 
            precision: {{options[:precision] || 15}}, 
            scale: {{options[:scale] || 6}}
        add :{{name}}_unit, :string, 
            limit: {{options[:unit_size] || 20}}
        
        {% if options[:required] %}
          change_column_null :{{table}}, :{{name}}_value, false
          change_column_null :{{table}}, :{{name}}_unit, false
        {% end %}
        
        {% if options[:default_unit] %}
          change_column_default :{{table}}, :{{name}}_unit, {{options[:default_unit].stringify}}
        {% end %}
        
        # Add check constraint for valid units
        execute <<-SQL
          ALTER TABLE {{table}}
          ADD CONSTRAINT chk_{{name}}_unit
          CHECK ({{name}}_unit IN (
            {% for unit in Unit.const_get(type).const_get(:Unit).values %}
              '{{unit}}'{%- unless forloop.last -%},{%- end -%}
            {% end %}
          ))
        SQL
        
        # Add index for common queries
        {% if options[:indexed] %}
          add_index :{{table}}, [:{{name}}_value, :{{name}}_unit]
        {% end %}
      end
      
      # Helper to remove measurement columns
      macro remove_measurement_column(table, name)
        remove :{{name}}_value
        remove :{{name}}_unit
      end
    end
  end
end
```

### 3. Factory Pattern for Type Creation

Use a factory pattern for creating appropriate types based on configuration:

```crystal
module Unit
  module Avram
    class TypeFactory
      def self.for_measurement(measurement_class : T.class) forall T
        case measurement_class
        when Weight::Measurement.class
          WeightMeasurementType
        when Length::Measurement.class
          LengthMeasurementType
        when Volume::Measurement.class
          VolumeMeasurementType
        else
          raise "Unknown measurement type: #{measurement_class}"
        end
      end
    end
  end
end
```

### 4. Performance Optimization Patterns

Implement caching and lazy loading for better performance:

```crystal
module Unit
  module Avram
    module PerformanceOptimizations
      # Cache parsed measurements
      @measurement_cache = {} of String => Measurement?
      
      def cached_parse(value : String) : Measurement?
        @measurement_cache[value] ||= parse_measurement(value)
      end
      
      # Batch loading for associations
      macro preload_measurements(*columns)
        def self.preload_measurements(records : Array(self))
          {% for column in columns %}
            # Preload and cache all measurements
            records.each do |record|
              record.{{column}} # Force loading
            end
          {% end %}
        end
      end
    end
  end
end
```

## Integration Example

Here's a complete example showing how everything fits together:

```crystal
# Model definition
class Product < BaseModel
  include Unit::Avram::ColumnExtensions
  include Unit::Avram::ValidationExtensions
  
  table do
    primary_key id : Int64
    column name : String
    
    # Use the measurement column macro
    measurement_columns :weight, Weight, required: true
    measurement_columns :dimensions, Length
    
    timestamps
  end
  
  # Add validations
  validate_measurement_range :weight, 
    Unit::Weight.new(0.1, :gram), 
    Unit::Weight.new(1000, :kilogram)
end

# Query usage
ProductQuery.new
  .with_weight_greater_than(Unit::Weight.new(5, :kilogram))
  .with_weight_between(
    Unit::Weight.new(5, :kilogram),
    Unit::Weight.new(10, :kilogram)
  )

# Operation usage
class SaveProduct < Product::SaveOperation
  before_save do
    # Automatic conversion happens
    weight.value = Unit::Weight.new(5.5, :kilogram)
  end
end

# Migration usage
class CreateProducts::V20240115000001 < Avram::Migrator::Migration::V1
  def migrate
    create table_for(Product) do
      primary_key id : Int64
      add_timestamped_columns
      add name : String
      
      add_measurement_column :products, :weight, :Weight,
        required: true,
        indexed: true,
        default_unit: "kilogram"
      
      add_measurement_column :products, :dimensions, :Length
    end
  end
  
  def rollback
    drop table_for(Product)
  end
end
```

This comprehensive approach to Avram integration provides type safety, performance optimization, and clean abstraction layers while maintaining the idiomatic Crystal and Lucky framework patterns. The implementation follows Avram's philosophy of compile-time safety and explicit behavior while extending its functionality to support your custom measurement types.


---

*Generated by Task Master Research Command*  
*Timestamp: 2025-08-01T16:18:08.929Z*
