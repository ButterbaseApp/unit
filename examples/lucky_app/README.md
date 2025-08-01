# Lucky Application Example with Unit Library

This example demonstrates how to integrate the Unit library with a Lucky web application using Avram ORM.

## Overview

This example shows:
- Database models with measurement columns
- Operations for saving and validating measurements
- Query methods for filtering by measurements
- Pages displaying measurement data
- Forms for inputting measurements

## Structure

```
lucky_app/
├── README.md
├── models/
│   └── product.cr
├── operations/
│   └── save_product.cr
├── queries/
│   └── product_query.cr
├── pages/
│   └── products/
│       ├── index_page.cr
│       └── form_fields.cr
└── actions/
    └── products/
        ├── index.cr
        └── create.cr
```

## Key Features

### 1. Product Model
- Stores products with weight, dimensions, and shipping information
- Uses measurement columns for type-safe storage

### 2. Save Operation
- Validates measurements (positive values, unit constraints)
- Handles string parsing from form inputs
- Calculates derived values (shipping weight)

### 3. Query Methods
- Filter products by weight range
- Find products within size constraints
- Sort by measurements

### 4. User Interface
- Forms with unit selection
- Display measurements in user-preferred units
- Responsive unit conversion

## Running the Example

This is a partial Lucky app example focusing on the Unit integration. To use these components:

1. Add them to your existing Lucky application
2. Run the migration to create the products table
3. Include the Unit shard in your `shard.yml`

## Database Migration

```crystal
class CreateProducts::V20240115000000 < Avram::Migrator::Migration::V1
  def migrate
    create table_for(Product) do
      primary_key id : Int64
      add_timestamped_columns
      add name : String
      add description : String?
      add sku : String, unique: true
      
      # Measurement columns
      add_measurement_column :weight, "Weight", required: true, indexed: true
      add_measurement_column :length, "Length", required: true
      add_measurement_column :width, "Length", required: true
      add_measurement_column :height, "Length", required: true
      
      add price_cents : Int32
      add stock_quantity : Int32, default: 0
    end
  end
  
  def rollback
    drop table_for(Product)
  end
end
```