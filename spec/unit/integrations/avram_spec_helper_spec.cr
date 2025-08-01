require "../../spec_helper"
require "../../../src/unit/integrations/avram"

# Mock Avram types for testing without a real database
module Avram
  module Type
    macro included
      extend self
    end

    class SuccessfulCast(T)
      getter :value

      def initialize(@value : T)
      end
    end

    class FailedCast
      def value
        nil
      end
    end
  end

  # Simple mock of Criteria - we don't need full functionality
  class Criteria(T, V)
  end

  class Database
  end
end

# Add blank? extension for String
class String
  def blank?
    empty? || match(/\A\s*\z/)
  end
end

# Test helpers for Avram integration
module AvramSpecHelper
  # Mock model for testing
  class TestModel
    property id : Int64?
    property name : String?

    # Simulated measurement storage
    property weight_value : Float64?
    property weight_unit : String?
    property length_value : Float64?
    property length_unit : String?
    property volume_value : Float64?
    property volume_unit : String?

    def initialize
    end
  end

  # Mock query builder
  class TestQuery
    getter conditions = [] of String
    getter bindings = [] of String | Float64 | BigDecimal

    def where(condition : String, *args)
      @conditions << condition
      args.each { |arg| @bindings << arg }
      self
    end

    def where(**kwargs)
      kwargs.each do |key, value|
        @conditions << "#{key} = ?"
        @bindings << value
      end
      self
    end

    def select_append(sql : String)
      @conditions << "SELECT_APPEND: #{sql}"
      self
    end
  end

  # Mock operation for testing validations
  class TestOperation
    alias ErrorMessage = String

    property errors = Hash(Symbol, Array(ErrorMessage)).new { |hash, key| hash[key] = [] of ErrorMessage }
    # Use a union of specific measurement types instead of the generic
    alias MeasurementTypes = Unit::Weight | Unit::Length | Unit::Volume | Nil
    property values = Hash(Symbol, MeasurementTypes).new

    def initialize
    end

    def add_error(field : Symbol, message : String)
      errors[field] << message
    end

    def valid?
      errors.empty?
    end

    # Define the FieldProxy class outside of method_missing
    class FieldProxy
      def initialize(@operation : TestOperation, @field : Symbol)
      end

      def value
        @operation.values[@field]?
      end

      def add_error(message : String)
        @operation.add_error(@field, message)
      end
    end

    macro method_missing(method)
      {% if method.name.ends_with?("=") %}
        {% field_name = method.name.gsub(/=$/, "") %}
        def {{method.name}}(value)
          @values[:{{field_name.id}}] = value
        end
      {% else %}
        def {{method.name}}
          FieldProxy.new(self, :{{method.name}})
        end
      {% end %}
    end
  end

  # Mock migration context
  class TestMigration
    getter executed_sql = [] of String
    getter columns = [] of NamedTuple(name: String, type: String, options: Hash(Symbol, String | Int32 | Bool))
    getter indexes = [] of NamedTuple(table: String, columns: Array(String))

    def add(name : Symbol, type, **options)
      # Ensure options hash has the right type
      typed_options = Hash(Symbol, String | Int32 | Bool).new
      options.each do |k, v|
        typed_options[k] = v.as(String | Int32 | Bool)
      end

      @columns << {
        name:    name.to_s,
        type:    type.to_s,
        options: typed_options,
      }
    end

    def add(name : Symbol, type : String, **options)
      # Ensure options hash has the right type
      typed_options = Hash(Symbol, String | Int32 | Bool).new
      options.each do |k, v|
        typed_options[k] = v.as(String | Int32 | Bool)
      end

      @columns << {
        name:    name.to_s,
        type:    type,
        options: typed_options,
      }
    end

    def change_null(column : Symbol, nullable : Bool)
      @executed_sql << "ALTER COLUMN #{column} SET #{nullable ? "NULL" : "NOT NULL"}"
    end

    def change_default(column : Symbol, default)
      @executed_sql << "ALTER COLUMN #{column} SET DEFAULT #{default}"
    end

    def execute(sql : String)
      @executed_sql << sql.strip
    end

    def add_index(table : Symbol, columns : Array(Symbol))
      @indexes << {
        table:   table.to_s,
        columns: columns.map(&.to_s),
      }
    end

    def create_index(table, column : Symbol)
      @indexes << {
        table:   table.to_s,
        columns: [column.to_s],
      }
    end

    def remove(column : Symbol)
      @columns.reject! { |col| col[:name] == column.to_s }
    end

    def remove_index(table : Symbol, columns : Array(Symbol))
      @indexes.reject! do |idx|
        idx[:table] == table.to_s && idx[:columns] == columns.map(&.to_s)
      end
    end
  end
end
