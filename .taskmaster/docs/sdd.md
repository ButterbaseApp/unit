# Software Design Document: Unit - A Crystal Measurement Library

## 1. Overview

### 1.1 Project Summary
Unit is a Crystal shard that provides a comprehensive measurement and unit conversion system, inspired by Shopify's Measured Ruby gem. It encapsulates measurements with their units, provides easy conversion between units, and includes built-in support for weight, length, volume, and extensible support for custom measurement types.

### 1.2 Key Objectives
- **Type Safety**: Leverage Crystal's compile-time type checking for measurement operations
- **Precision**: Use Crystal's `BigDecimal` and `BigRational` for accurate conversions
- **Extensibility**: Simple DSL for adding new measurement types and units
- **Performance**: Compile-time optimizations and efficient conversion algorithms
- **Integration**: Native Avram/Lucky framework integration for database persistence
- **Crystal Idioms**: Follow Crystal conventions rather than Ruby patterns

### 1.3 Core Features
- Measurement creation with automatic unit validation
- Seamless unit conversion with precision handling
- Arithmetic operations between compatible measurements
- String parsing and formatting
- Database persistence via Avram integration
- SI unit prefix support
- Custom measurement type creation

## 2. Architecture Overview

### 2.1 Module Structure
```
Unit/
├── src/
│   ├── unit.cr                    # Main entry point
│   ├── unit/
│   │   ├── measurement.cr         # Base measurement class
│   │   ├── measurable.cr          # Measurement behavior module
│   │   ├── arithmetic.cr          # Mathematical operations
│   │   ├── unit_system.cr         # Unit system management
│   │   ├── unit_definition.cr     # Individual unit definitions
│   │   ├── conversion_table.cr    # Conversion calculations
│   │   ├── parser.cr              # String parsing utilities
│   │   ├── formatter.cr           # Display formatting
│   │   ├── builder.cr             # DSL for creating measurement types
│   │   ├── exceptions.cr          # Custom error types
│   │   ├── measurements/          # Built-in measurement types
│   │   │   ├── weight.cr
│   │   │   ├── length.cr
│   │   │   └── volume.cr
│   │   └── integrations/
│   │       └── avram.cr           # Lucky/Avram integration
│   └── unit/
└── spec/                          # Test suite
```

### 2.2 Core Types

#### 2.2.1 Base Types
```crystal
# Numeric types for precise calculations
alias MeasurementValue = BigDecimal | BigRational | Int32 | Int64 | Float64

# Phantom types for measurement categories using enums
enum Unit::MeasurementType
  Weight
  Length
  Volume
end

# Generic measurement type with phantom typing
class Unit::Measurement(T : Unit::MeasurementType)
  getter value : BigDecimal
  getter unit : Unit::UnitDefinition
  
  def initialize(@value : MeasurementValue, @unit : Enum)
    @value = convert_to_bigdecimal(value)
    @unit = resolve_unit_from_enum(unit)
  end
  
  # Type-safe arithmetic - only same phantom types can be combined
  def +(other : Unit::Measurement(T)) : Unit::Measurement(T)
    converted_other = other.convert_to(@unit.name)
    self.class.new(@value + converted_other.value, @unit.name)
  end
end
```

#### 2.2.2 Unit Enums and Type Aliases
```crystal
# Weight units enum with Crystal-style naming
enum Unit::Weight::Unit
  # Base SI unit
  Gram
  Kilogram
  
  # Metric units
  Milligram
  Tonne
  
  # Imperial units  
  Pound
  Ounce
  Slug
  
  # Aliases for convenience
  G    = Gram
  Kg   = Kilogram
  Mg   = Milligram
  T    = Tonne
  Lb   = Pound
  Oz   = Ounce
end

enum Unit::Length::Unit
  # Base SI unit
  Meter
  
  # Metric with SI prefixes
  Millimeter
  Centimeter
  Kilometer
  
  # Imperial units
  Inch
  Foot
  Yard
  Mile
  
  # Aliases
  M    = Meter
  Mm   = Millimeter  
  Cm   = Centimeter
  Km   = Kilometer
  In   = Inch
  Ft   = Foot
  Yd   = Yard
  Mi   = Mile
end

enum Unit::Volume::Unit
  # Base SI unit
  Liter
  
  # Metric with SI prefixes
  Milliliter
  
  # Imperial units
  Gallon
  Quart
  Pint
  Cup
  FluidOunce
  
  # Aliases
  L     = Liter
  Ml    = Milliliter
  Gal   = Gallon
  Qt    = Quart
  Pt    = Pint
  FlOz  = FluidOunce
end

# Type aliases for clean API
alias Unit::Weight = Unit::Measurement(Unit::MeasurementType::Weight)
alias Unit::Length = Unit::Measurement(Unit::MeasurementType::Length)
alias Unit::Volume = Unit::Measurement(Unit::MeasurementType::Volume)
```

### 2.3 Key Design Patterns

#### 2.3.1 Generic Type Safety with Enums
Using Crystal phantom types and enums to ensure type safety at compile time:
```crystal
weight1 = Unit::Weight.new(10, Unit::Weight::Unit::Kg)
weight2 = Unit::Weight.new(5, Unit::Weight::Unit::Lb)
total = weight1 + weight2  # ✓ Valid: same measurement type

# Convenient aliases work too
weight3 = Unit::Weight.new(10, Unit::Weight::Unit::Kilogram)  # Same as ::Kg
weight4 = Unit::Weight.new(5, Unit::Weight::Unit::Pound)     # Same as ::Lb

length = Unit::Length.new(1, Unit::Length::Unit::M)
invalid = weight1 + length  # ✗ Compile-time error: incompatible phantom types

# This also prevents unit mixing at compile time
bad_weight = Unit::Weight.new(10, Unit::Length::Unit::M)  # ✗ Compile-time error
```

**Benefits of this approach:**
- **Compile-time safety**: Invalid unit combinations caught during compilation
- **IDE support**: Full autocomplete for unit names with `Unit::Weight::Unit::`
- **No runtime errors**: Typos in unit names become compile-time errors
- **Performance**: Enum comparisons are faster than string comparisons
- **Namespacing**: Units are properly scoped to their measurement types
- **Crystal idioms**: Uses enums instead of symbols, following Crystal conventions

#### 2.3.2 Builder Pattern for Unit Systems
```crystal
Unit::Temperature = Unit.build do
  base_unit :kelvin, aliases: [:k]
  unit :celsius, value: ->(k : BigDecimal) { k - 273.15 }, aliases: [:c]
  unit :fahrenheit, value: ->(k : BigDecimal) { (k - 273.15) * 9/5 + 32 }, aliases: [:f]
end
```

#### 2.3.3 Mixin Architecture
```crystal
module Unit::Measurable(T)
  include Comparable(T)
  
  # Arithmetic operations
  def +(other : T) : T
  def -(other : T) : T
  def scale(factor : Number) : T
  
  # Conversions
  def convert_to(new_unit : UnitName) : T
  
  # Formatting
  def to_s(format : String? = nil) : String
  def humanize : String
end
```

## 3. Core Components

### 3.1 Unit System (`Unit::UnitSystem`)

#### 3.1.1 Responsibilities
- Manage unit definitions and aliases
- Build conversion tables
- Validate unit names
- Perform unit conversions

#### 3.1.2 Interface
```crystal
class Unit::UnitSystem
  getter base_unit : Unit::UnitDefinition
  getter units : Hash(String, Unit::UnitDefinition)
  getter aliases : Hash(String, String)
  
  def initialize(@base_unit)
  end
  
  def add_unit(name : String, definition : Unit::UnitDefinition)
  def unit_for(name : UnitName) : Unit::UnitDefinition?
  def unit_for!(name : UnitName) : Unit::UnitDefinition
  def convert(value : BigDecimal, from : UnitDefinition, to : UnitDefinition) : BigDecimal
  def valid_unit?(name : UnitName) : Bool
  def unit_names : Array(String)
  def unit_names_with_aliases : Array(String)
end
```

### 3.2 Unit Definition (`Unit::UnitDefinition`)

#### 3.2.1 Purpose
Represents a single unit with its conversion factor and metadata.

#### 3.2.2 Structure
```crystal
class Unit::UnitDefinition
  getter name : String
  getter aliases : Array(String)
  getter conversion_factor : BigDecimal
  getter conversion_offset : BigDecimal
  
  def initialize(@name, @aliases = [] of String, @conversion_factor = BigDecimal.new(1), @conversion_offset = BigDecimal.new(0))
  end
  
  def ==(other : UnitDefinition) : Bool
  def to_s(with_conversion : Bool = true) : String
end
```

### 3.3 Conversion Table (`Unit::ConversionTable`)

#### 3.3.1 Algorithm
Uses Floyd-Warshall algorithm to find optimal conversion paths between units.

#### 3.3.2 Implementation
```crystal
class Unit::ConversionTable
  private getter table : Hash(String, Hash(String, BigDecimal))
  
  def initialize(units : Hash(String, Unit::UnitDefinition), base_unit : String)
    build_conversion_table(units, base_unit)
  end
  
  def convert(value : BigDecimal, from : String, to : String) : BigDecimal
  private def build_conversion_table(units, base_unit)
    # Floyd-Warshall implementation
  end
end
```

### 3.4 Parser (`Unit::Parser`)

#### 3.4.1 Purpose
Parse string representations into value/unit pairs.

#### 3.4.2 Supported Formats
- `"10 kg"` → `{BigDecimal.new(10), "kg"}`
- `"3.14159 meters"` → `{BigDecimal.new("3.14159"), "meters"}`
- `"1/2 lb"` → `{BigRational.new(1, 2), "lb"}`
- `"15.5kg"` → `{BigDecimal.new("15.5"), "kg"}`

#### 3.4.3 Interface
```crystal
module Unit::Parser
  def self.parse(input : String) : Tuple(BigDecimal, String)
  private def self.extract_value(str : String) : BigDecimal
  private def self.extract_unit(str : String) : String
end
```

### 3.5 Formatter (`Unit::Formatter`)

#### 3.5.1 Purpose
Convert measurements to human-readable strings with configurable formatting.

#### 3.5.2 Format Options
```crystal
module Unit::Formatter
  DEFAULT_FORMAT = "%.2f %s"
  
  def self.format(measurement : Unit::Measurement, format : String? = nil, *, 
                  with_conversion : Bool = true) : String
  def self.humanize(measurement : Unit::Measurement) : String
end
```

## 4. Built-in Measurement Types

### 4.1 Weight (`Unit::Weight`)
The weight measurement system is built around the gram as the base unit, with enum-based unit definitions:

```crystal
# Enum definition (as shown in section 2.2.2)
enum Unit::Weight::Unit
  Gram; Kilogram; Milligram; Tonne
  Pound; Ounce; Slug
  
  # Convenient aliases
  G = Gram; Kg = Kilogram; Mg = Milligram; T = Tonne
  Lb = Pound; Oz = Ounce
end

# Conversion factors stored internally
WEIGHT_CONVERSIONS = {
  Unit::Weight::Unit::Gram      => BigDecimal.new(1),           # Base unit
  Unit::Weight::Unit::Kilogram  => BigDecimal.new(1000),        # 1000g
  Unit::Weight::Unit::Milligram => BigDecimal.new("0.001"),     # 0.001g
  Unit::Weight::Unit::Tonne     => BigDecimal.new(1_000_000),   # 1,000,000g
  Unit::Weight::Unit::Pound     => BigDecimal.new("453.59237"), # 453.59237g
  Unit::Weight::Unit::Ounce     => BigDecimal.new("28.349523"), # 28.349523g
  Unit::Weight::Unit::Slug      => BigDecimal.new("14593.903"), # 14593.903g
}
```

### 4.2 Length (`Unit::Length`)
The length measurement system uses meter as the base unit:

```crystal
# Enum definition
enum Unit::Length::Unit
  Meter; Millimeter; Centimeter; Kilometer
  Inch; Foot; Yard; Mile
  
  # Aliases
  M = Meter; Mm = Millimeter; Cm = Centimeter; Km = Kilometer
  In = Inch; Ft = Foot; Yd = Yard; Mi = Mile
end

# Conversion factors (in meters)
LENGTH_CONVERSIONS = {
  Unit::Length::Unit::Meter      => BigDecimal.new(1),        # Base unit
  Unit::Length::Unit::Millimeter => BigDecimal.new("0.001"),  # 0.001m
  Unit::Length::Unit::Centimeter => BigDecimal.new("0.01"),   # 0.01m
  Unit::Length::Unit::Kilometer  => BigDecimal.new(1000),     # 1000m
  Unit::Length::Unit::Inch       => BigDecimal.new("0.0254"), # 0.0254m
  Unit::Length::Unit::Foot       => BigDecimal.new("0.3048"), # 0.3048m
  Unit::Length::Unit::Yard       => BigDecimal.new("0.9144"), # 0.9144m
  Unit::Length::Unit::Mile       => BigDecimal.new("1609.344"), # 1609.344m
}
```

### 4.3 Volume (`Unit::Volume`)
The volume measurement system uses liter as the base unit:

```crystal
# Enum definition
enum Unit::Volume::Unit
  Liter; Milliliter
  Gallon; Quart; Pint; Cup; FluidOunce
  
  # Aliases
  L = Liter; Ml = Milliliter
  Gal = Gallon; Qt = Quart; Pt = Pint; FlOz = FluidOunce
end

# Conversion factors (in liters)
VOLUME_CONVERSIONS = {
  Unit::Volume::Unit::Liter      => BigDecimal.new(1),            # Base unit
  Unit::Volume::Unit::Milliliter => BigDecimal.new("0.001"),      # 0.001L
  Unit::Volume::Unit::Gallon     => BigDecimal.new("3.785411784"), # 3.785411784L (US)
  Unit::Volume::Unit::Quart      => BigDecimal.new("0.946352946"), # 0.946352946L
  Unit::Volume::Unit::Pint       => BigDecimal.new("0.473176473"), # 0.473176473L
  Unit::Volume::Unit::Cup        => BigDecimal.new("0.236588237"), # 0.236588237L
  Unit::Volume::Unit::FluidOunce => BigDecimal.new("0.0295735297"), # 0.0295735297L
}
```

## 5. Avram Integration

### 5.1 Database Schema
```crystal
# Migration
class CreateProducts::V1 < Avram::Migrator::Migration::V1
  def migrate
    create table_for(Product) do
      primary_key id : Int64
      add_timestamps
      
      add weight_value : BigDecimal?, precision: 10, scale: 4
      add weight_unit : String?
      add dimensions_length_value : BigDecimal?, precision: 10, scale: 4
      add dimensions_length_unit : String?
    end
  end
end
```

### 5.2 Model Integration
```crystal
class Product < BaseModel
  include Unit::Avram::Measurable
  
  table do
    primary_key id : Int64
    timestamps
    
    column weight_value : BigDecimal?
    column weight_unit : String?
    column dimensions_length_value : BigDecimal?
    column dimensions_length_unit : String?
  end
  
  # Measurement columns
  measurement weight : Unit::Weight?, from: {weight_value, weight_unit}
  measurement dimensions_length : Unit::Length?, from: {dimensions_length_value, dimensions_length_unit}
end
```

### 5.3 Usage Example
```crystal
# Create product with measurements
product = ProductSaveOperation.create!(
  weight: Unit::Weight.new(2.5, :kg),
  dimensions_length: Unit::Length.new(30, :cm)
)

# Query and convert
heavy_products = ProductQuery.new
  .weight_value.gt(1000)  # Assuming grams as stored unit
  .results

product.weight.try(&.convert_to(:lb))  # Convert to pounds
```

### 5.4 Validation Integration
```crystal
class ProductSaveOperation < Product::SaveOperation
  before_save do
    validate_measurement_units
  end
  
  private def validate_measurement_units
    if weight.value && !Unit::Weight.valid_unit?(weight_unit.value)
      weight_unit.add_error("is not a valid weight unit")
    end
  end
end
```

## 6. Error Handling

### 6.1 Exception Hierarchy
```crystal
module Unit
  class Error < Exception; end
  
  class UnitError < Error; end
  class UnknownUnitError < UnitError; end
  class IncompatibleUnitsError < UnitError; end
  class ConversionError < UnitError; end
  class ParseError < Error; end
  
  class ValidationError < Error; end
  class InvalidValueError < ValidationError; end
  class BlankValueError < ValidationError; end
end
```

### 6.2 Error Scenarios
- Unknown unit names → `UnknownUnitError`
- Arithmetic between incompatible types → `IncompatibleUnitsError`
- Invalid string parsing → `ParseError`
- Blank/nil values → `BlankValueError`
- Circular unit dependencies → `ConversionError`

## 7. Performance Considerations

### 7.1 Compile-Time Optimizations
- Generic specialization for common measurement types
- Inline conversion factors where possible
- Pre-computed conversion tables

### 7.2 Runtime Optimizations
- Cached conversion tables stored as JSON
- Lazy loading of unit systems
- Efficient string parsing with minimal allocations

### 7.3 Memory Management
- Immutable measurement objects
- String deduplication for unit names
- Reuse of common BigDecimal instances

## 8. Testing Strategy

### 8.1 Unit Tests
- Individual component testing (unit systems, conversions, parsing)
- Edge case handling (precision, rounding, large numbers)
- Error condition testing

### 8.2 Integration Tests
- Avram model integration
- Cross-measurement-type interactions
- Database persistence and retrieval

### 8.3 Performance Tests
- Conversion speed benchmarks
- Memory usage profiling
- Large dataset handling

## 9. API Examples

### 9.1 Basic Usage
```crystal
# Create measurements with enum units
weight = Unit::Weight.new(10, Unit::Weight::Unit::Kg)
length = Unit::Length.new(5, Unit::Length::Unit::Ft)

# Use convenient aliases
weight_alt = Unit::Weight.new(10, Unit::Weight::Unit::Kilogram)  # Same as ::Kg
short_form = Unit::Weight.new(10, Unit::Weight::Unit::G)         # Grams

# Convert units
weight_in_pounds = weight.convert_to(Unit::Weight::Unit::Lb)  # 22.05 lb
length_in_meters = length.convert_to(Unit::Length::Unit::M)   # 1.52 m

# Type-safe arithmetic - compile-time safety
total_weight = Unit::Weight.new(5, Unit::Weight::Unit::Kg) + 
               Unit::Weight.new(10, Unit::Weight::Unit::Lb)  # 9.54 kg
doubled = weight.scale(2)  # 20 kg

# This won't compile - different measurement types
# invalid = weight + length  # ✗ Compile-time error

# Parsing from strings (when unit types can be inferred)
parsed = Unit::Weight.parse("15.5 kg")  # Infers Unit::Weight::Unit::Kg

# Formatting
weight.to_s                    # "10.00 kg"
weight.to_s("%.1f %s")        # "10.0 kg"
weight.humanize               # "10 kilograms"
```

### 9.2 Custom Measurements
```crystal
Unit::Temperature = Unit.build do
  base_unit :kelvin, aliases: [:k]
  
  unit :celsius, 
    to_base: ->(c : BigDecimal) { c + 273.15 },
    from_base: ->(k : BigDecimal) { k - 273.15 },
    aliases: [:c]
    
  unit :fahrenheit,
    to_base: ->(f : BigDecimal) { (f - 32) * 5/9 + 273.15 },
    from_base: ->(k : BigDecimal) { (k - 273.15) * 9/5 + 32 },
    aliases: [:f]
end

temp = Unit::Temperature.new(25, :celsius)
temp_f = temp.convert_to(:fahrenheit)  # 77°F
```

### 9.3 Database Integration
```crystal
# Model with measurements
class Recipe < BaseModel
  include Unit::Avram::Measurable
  
  measurement serving_weight : Unit::Weight
  measurement cook_time : Unit::Time
end

# Save with measurements
recipe = RecipeSaveOperation.create!(
  name: "Chocolate Cake",
  serving_weight: Unit::Weight.new(150, :g),
  cook_time: Unit::Time.new(45, :minutes)
)

# Query by measurement
heavy_servings = RecipeQuery.new
  .serving_weight_in_grams.gt(200)
  .results
```

## 10. Migration Path

### 10.1 From Ruby Measured
- Similar API surface for easy migration
- Documentation with Ruby → Crystal examples
- Migration guide for common patterns

### 10.2 Breaking Changes from Ruby
- Strong typing (compile-time errors vs runtime)
- Crystal naming conventions (snake_case methods)
- No ActiveRecord integration (Avram instead)
- Different numeric type handling

## 11. Future Extensions

### 11.1 Additional Measurement Types
- Temperature (Celsius, Fahrenheit, Kelvin)
- Pressure (Pascal, PSI, Bar)  
- Energy (Joule, Calorie, BTU)
- Power (Watt, Horsepower)
- Speed (m/s, mph, knots)

### 11.2 Advanced Features
- Compound units (m/s², kg⋅m/s²)
- Unit dimension analysis
- Scientific notation support
- Localization for unit names
- JSON serialization for APIs

### 11.3 Framework Integrations
- JSON::Serializable support
- YAML::Serializable support  
- HTTP::Params parsing
- GraphQL scalar types

## 12. Conclusion

Unit provides a comprehensive, type-safe measurement library for Crystal that emphasizes precision, performance, and Crystal idioms. The design balances familiarity for Ruby developers with Crystal's strengths in compile-time safety and performance optimization.

The modular architecture allows for easy extension while maintaining a clean, intuitive API. Integration with Avram provides seamless database persistence, making it suitable for real-world applications requiring measurement handling.