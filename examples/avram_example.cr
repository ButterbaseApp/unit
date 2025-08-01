# Avram Integration Demo for Unit Library
#
# This file demonstrates how to use the Unit library with Lucky Framework's Avram ORM.
# Due to a compilation issue with Avram examples outside of a Lucky app context,
# this is a demonstration of the API rather than a runnable example.

# 1. In your Lucky app, add Unit to your shard.yml:
#
# dependencies:
#   unit:
#     github: watzon/unit

# 2. Require the Avram integration in your app:
#
# # In src/shards.cr or similar
# require "unit/integrations/avram"

# 3. Define models with measurement columns:
#
# class Product < BaseModel
#   table do
#     primary_key id : Int64
#     column name : String
#     column description : String?
#
#     # Define the underlying columns for measurements
#     column weight_value : Float64
#     column weight_unit : String
#     column length_value : Float64?
#     column length_unit : String?
#   end
# end
#
# # Add measurement functionality after the model definition
# class Product
#   include Unit::Avram::ColumnExtensions
#   include Unit::Avram::ValidationExtensions
#
#   # Define measurement accessors
#   define_measurement_accessors :weight, Weight, required: true
#   define_measurement_accessors :length, Length
#
#   # Add validations
#   validate_measurement_positive :weight
#   validate_measurement_range :length,
#     Unit::Length.new(0.1, :centimeter),
#     Unit::Length.new(100, :meter)
# end

# 4. Create queries with measurement-aware methods:
#
# class ProductQuery < Product::BaseQuery
#   include Unit::Avram::QueryExtensions
#
#   # Add query methods for measurements
#   measurement_query_methods :weight, Weight
#   measurement_query_methods :length, Length
# end

# 5. Use in operations:
#
# class SaveProduct < Product::SaveOperation
#   permit_columns name, description, weight_value, weight_unit,
#                  length_value, length_unit
#
#   # Custom setter from string
#   def set_weight_from_string(value : String)
#     self.weight = Unit::Parser.parse(Unit::Weight, value)
#   end
# end

# 6. Create migrations with measurement helpers:
#
# class CreateProducts::V20240115000001 < Avram::Migrator::Migration::V1
#   include Unit::Avram::MigrationHelpers
#
#   def migrate
#     create table_for(Product) do
#       primary_key id : Int64
#       add_timestamps
#       add name : String
#       add description : String?
#
#       # Use the migration helper
#       add_measurement_column :products, :weight, :Weight,
#         required: true,
#         indexed: true
#
#       add_measurement_column :products, :length, :Length
#     end
#   end
#
#   def rollback
#     drop table_for(Product)
#   end
# end

# 7. Example usage in your app:
#
# # Create a product
# SaveProduct.create(
#   name: "Heavy Box",
#   weight_value: 25.5,
#   weight_unit: "kilogram",
#   length_value: 100.0,
#   length_unit: "centimeter"
# ) do |operation, product|
#   if product
#     puts product.weight              # => Unit::Weight instance
#     puts product.weight_in(:pound)   # => BigDecimal value in pounds
#   end
# end
#
# # Query products
# heavy_products = ProductQuery.new
#   .with_weight_greater_than(Unit::Weight.new(20, :kilogram))
#   .with_weight_less_than(Unit::Weight.new(50, :kilogram))
#
# # Query by unit
# metric_products = ProductQuery.new
#   .with_weight_unit(Unit::Weight::Unit::Kilogram)

puts "Unit library Avram integration features:"
puts ""
puts "✓ Type-safe measurement columns with automatic serialization"
puts "✓ Query extensions with automatic unit conversion"
puts "✓ Validation helpers for measurements"
puts "✓ Migration helpers for easy setup"
puts "✓ PostgreSQL optimizations (NUMERIC types, enums, JSONB)"
puts "✓ Aggregate functions with unit awareness"
puts ""
puts "See docs/avram-integration.md for complete documentation."
