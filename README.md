# unit

[![GitHub release](https://img.shields.io/github/release/ButterbaseApp/unit.svg)](https://github.com/ButterbaseApp/unit/releases)
[![Build Status](https://github.com/ButterbaseApp/unit/workflows/CI/badge.svg)](https://github.com/ButterbaseApp/unit/actions)
[![Crystal Version](https://img.shields.io/badge/crystal-%3E%3D1.0.0-brightgreen.svg)](https://crystal-lang.org/)
[![License](https://img.shields.io/github/license/ButterbaseApp/unit.svg)](https://github.com/ButterbaseApp/unit/blob/main/LICENSE)

Type-safe, compile-time unit conversions for Crystal with zero runtime overhead and arbitrary precision arithmetic.

## Table of Contents

- [Background](#background)
- [Install](#install)
- [Usage](#usage)
  - [Numeric Extensions (Optional)](#numeric-extensions-optional)
  - [Basic Conversions](#basic-conversions)
  - [Arithmetic Operations](#arithmetic-operations)
  - [String Parsing](#string-parsing)
  - [Formatting and Display](#formatting-and-display)
  - [Comparison and Equality](#comparison-and-equality)
  - [Type Safety](#type-safety)
  - [Advanced Precision](#advanced-precision)
  - [Scientific Computing](#scientific-computing)
  - [Recipe and Cooking Applications](#recipe-and-cooking-applications)
- [API](#api)
  - [Measurement Types](#measurement-types)
  - [Core Methods](#core-methods)
  - [Parser](#parser)
  - [Formatter](#formatter)
  - [Exceptions](#exceptions)
- [Integrations](#integrations)
  - [Avram ORM](#avram-orm)
  - [Lucky Framework](#lucky-framework)
  - [JSON/YAML Serialization](#jsonyaml-serialization)
  - [Database Storage](#database-storage)
- [Advanced Features](#advanced-features)
  - [Phantom Type System](#phantom-type-system)
  - [BigDecimal Precision](#bigdecimal-precision)
  - [Custom Validation](#custom-validation)
  - [Performance Optimizations](#performance-optimizations)
- [Examples](#examples)
- [Contributing](#contributing)
- [License](#license)

## Background

The Unit library provides a robust, type-safe system for handling measurements and unit conversions in Crystal applications. Built with modern software engineering principles, it addresses common challenges faced by developers working with physical measurements in scientific, engineering, culinary, and commercial applications.

**Core Problems Solved:**
- **Type Safety**: Prevents mixing incompatible units at compile time (can't add meters to kilograms)
- **Precision Loss**: Eliminates floating-point rounding errors through BigDecimal arithmetic
- **Runtime Errors**: Catches unit conversion mistakes during compilation, not in production
- **Database Integration**: Seamlessly stores and queries measurements in databases
- **User Input**: Robust parsing of natural language measurement strings
- **International Standards**: Uses exact NIST/ISO conversion factors for scientific accuracy

**Key Features:**
- **Phantom Type System**: Compile-time type safety using Crystal's advanced type system
- **Arbitrary Precision**: BigDecimal arithmetic prevents floating-point errors
- **Zero Runtime Overhead**: All type checking happens at compile time
- **Numeric Extensions**: Optional convenient syntax like `5.grams` and `1.2.kg` for intuitive measurement creation
- **Scientific Accuracy**: Uses exact conversion factors from international standards
- **Framework Integration**: Deep integration with Lucky/Avram for web applications
- **Natural Language Parsing**: Flexible string parsing including fractions and aliases
- **Database Persistence**: Type-safe storage with automatic serialization
- **International Support**: Metric and Imperial units with proper conversions
- **Extensible Architecture**: Easy to add new measurement types and units

**Supported Measurement Types:**
- **Weight/Mass**: Gram, Kilogram, Pound, Ounce, Tonne, Milligram, Slug
- **Length/Distance**: Meter, Centimeter, Foot, Inch, Kilometer, Mile, Yard, Millimeter
- **Volume/Liquid**: Liter, Milliliter, Gallon, Cup, FluidOunce, Pint, Quart
- **Density**: Gram per milliliter, Kilogram per liter, Gram per cm³, Pound per gallon, etc.

**Use Cases:**
- Scientific computing with precise calculations
- Recipe scaling and cooking applications with ingredient density conversions
- E-commerce product specifications with dimensional weight calculations
- Engineering and CAD applications with material density analysis
- IoT sensor data processing with mass-volume relationships
- Financial calculations with physical commodities
- International trade and shipping with freight density optimization
- Educational tools and calculators
- Chemistry and physics laboratory calculations

## Install

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     unit:
       github: ButterbaseApp/unit
   ```

2. Run `shards install`

## Usage

```crystal
require "unit"
```

### Numeric Extensions (Optional)

For even more convenient measurement creation, you can optionally require the numeric extensions:

```crystal
require "unit"
require "unit/extensions"  # Optional - enables convenient syntax

# With extensions enabled, you can create measurements directly from numbers:
weight = 5.grams           # => Unit::Weight.new(5, :gram)
length = 1.2.meters        # => Unit::Length.new(1.2, :meter)
volume = 500.ml            # => Unit::Volume.new(500, :milliliter)

# All numeric types supported:
precise = BigDecimal.new("3.14159").grams
big_num = 1000000_i64.kg
float = 2.5_f32.liters

# Works seamlessly with arithmetic:
total = 5.grams + 2.kg + 500.mg  # => 2005.50 gram
distance = 1.meter + 50.cm + 25.mm  # => 1.52 meter

# Available methods for each measurement type:
# Weight: .grams, .gram, .g, .kilograms, .kg, .pounds, .lb, etc.
# Length: .meters, .m, .centimeters, .cm, .feet, .ft, .inches, .in, etc.
# Volume: .liters, .l, .milliliters, .ml, .cups, .gallons, .gal, etc.
# Density: .g_per_ml, .kg_per_l, .g_per_cc, .lb_per_gal, .lb_per_ft3, etc.
```

The extensions are optional and don't pollute the global namespace unless explicitly required. Without extensions, the standard constructor syntax remains available:

```crystal
# Standard syntax (always available):
weight = Unit::Weight.new(5, :gram)
length = Unit::Length.new(1.2, :meter)
volume = Unit::Volume.new(500, :milliliter)
```

### Basic Conversions

Create measurements and convert between units with type safety and precision:

```crystal
# Create measurements using symbols or enum values
weight = Unit::Weight.new(5.5, :kilogram)
length = Unit::Length.new(100, :centimeter)
volume = Unit::Volume.new(2, :liter)

# Alternative creation with enum values
weight = Unit::Weight.new(5.5, Unit::Weight::Unit::Kilogram)

# Convert to different units
pounds = weight.convert_to(:pound)      # => 12.125 lbs
meters = length.convert_to(:meter)      # => 1.0 m
gallons = volume.convert_to(:gallon)    # => 0.528344 gal

# Use the convenient 'to' alias
inches = length.to(:inch)               # => 39.3701 in

# Access underlying values
weight.value                            # => BigDecimal("5.5")
weight.unit                             # => Unit::Weight::Unit::Kilogram
```

### Arithmetic Operations

Perform arithmetic with automatic unit conversion and precision preservation:

```crystal
# Addition (converts to first operand's unit)
total_weight = Unit::Weight.new(5, :kilogram) + Unit::Weight.new(10, :pound)
# => 9.5359237 kg (exact conversion)

# Subtraction with mixed units  
difference = Unit::Length.new(2, :meter) - Unit::Length.new(50, :centimeter)
# => 1.5 m

# Scalar multiplication and division
double_weight = weight * 2              # => 11.0 kg
half_length = length / 2                # => 50.0 cm
quarter_volume = volume / 4             # => 0.5 L

# Complex expressions with chaining
result = ((weight + Unit::Weight.new(1, :pound)) * 2) - Unit::Weight.new(500, :gram)
# => 11.4071874 kg

# Supports all numeric types
weight * BigDecimal.new("1.5")         # => 8.25 kg
length * 0.5                           # => 50.0 cm
```

### String Parsing

Parse measurements from natural language strings with flexible formats:

```crystal
# Basic decimal parsing
weight = Unit::Parser.parse("10.5 kg", Unit::Weight)
length = Unit::Parser.parse("5.25 meters", Unit::Length)

# Fraction support (exact rational arithmetic)
weight = Unit::Parser.parse("1 1/2 pounds", Unit::Weight)      # => 1.5 lbs
volume = Unit::Parser.parse("2 3/4 cups", Unit::Volume)        # => 2.75 cups
length = Unit::Parser.parse("1/2 foot", Unit::Length)          # => 0.5 ft

# Unit aliases and variations
Unit::Parser.parse("10 kilos", Unit::Weight)          # "kilos" -> kilogram
Unit::Parser.parse("6 ft", Unit::Length)              # "ft" -> foot  
Unit::Parser.parse("2 lbs", Unit::Weight)             # "lbs" -> pound
Unit::Parser.parse("5 fl oz", Unit::Volume)           # "fl oz" -> fluid_ounce

# Flexible whitespace and formatting
Unit::Parser.parse("10kg", Unit::Weight)              # No space
Unit::Parser.parse("10 kg", Unit::Weight)             # Single space
Unit::Parser.parse("10   kg", Unit::Weight)           # Multiple spaces
Unit::Parser.parse("  10.5  KILOGRAMS  ", Unit::Weight) # Case insensitive

# Scientific notation and large numbers
Unit::Parser.parse("1.5e3 g", Unit::Weight)           # => 1500 g
Unit::Parser.parse("-273.15 m", Unit::Length)         # Negative values
```

### Formatting and Display

Format measurements for display with customizable precision and styles:

```crystal
weight = Unit::Weight.new(5.5, :kilogram)

# Default string representation
weight.to_s                             # => "5.5 kg"

# Custom precision control (0-10 decimal places)
weight.format(precision: 0)             # => "6 kg"
weight.format(precision: 2)             # => "5.50 kg"
weight.format(precision: 4)             # => "5.5000 kg"

# Unit format options
weight.format(unit_format: :short)      # => "5.5 kg"
weight.format(unit_format: :long)       # => "5.5 kilogram"

# Combined formatting
weight.format(precision: 1, unit_format: :long)  # => "5.5 kilogram"

# Humanized output with intelligent pluralization
weight.humanize                         # => "5.5 kilograms"
Unit::Weight.new(1, :kilogram).humanize          # => "1 kilogram"
Unit::Length.new(2, :foot).humanize              # => "2 feet"
Unit::Length.new(1, :inch).humanize              # => "1 inch"

# Special cases handled properly
Unit::Weight.new(0, :gram).humanize              # => "0 grams"
Unit::Weight.new(-1, :kilogram).humanize         # => "-1 kilogram"
```

### Comparison and Equality

Compare measurements across different units with automatic conversion:

```crystal
# Equality with automatic unit conversion
kg = Unit::Weight.new(1, :kilogram)
g = Unit::Weight.new(1000, :gram)
kg == g                                 # => true

# All comparison operators work
heavy = Unit::Weight.new(100, :kilogram)
light = Unit::Weight.new(10, :pound)
heavy > light                           # => true
heavy >= light                          # => true
light < heavy                           # => true

# Hash equality (equivalent measurements have same hash)
{kg => "metric"} == {g => "metric"}     # => true

# Sorting works by actual value, not numeric value
weights = [
  Unit::Weight.new(5, :kilogram),       # 5000g
  Unit::Weight.new(10, :pound),         # ≈4536g  
  Unit::Weight.new(1000, :gram)         # 1000g
]
weights.sort                            # [1000g, 10 lbs, 5kg]

# Set deduplication
[kg, g].to_set.size                     # => 1 (treated as same value)
```

### Type Safety

The phantom type system prevents invalid operations at compile time:

```crystal
weight = Unit::Weight.new(10, :kilogram)
length = Unit::Length.new(5, :meter)

# These won't compile - mixing incompatible measurement types
# total = weight + length               # Compile error!
# comparison = weight > length          # Compile error!
# array = [weight, length]              # Compile error!

# Type-safe function parameters
def calculate_shipping_cost(weight : Unit::Weight)
  weight.convert_to(:pound).value * 0.5
end

calculate_shipping_cost(weight)         # ✓ Valid
# calculate_shipping_cost(length)       # Compile error!

# Collections are type-safe
weights = Array(Unit::Weight).new       # Only accepts Weight measurements
weights << Unit::Weight.new(1, :kilogram)  # ✓ Valid
# weights << length                     # Compile error!

# But scalar operations work fine
doubled = weight * 2                    # => 20 kg
halved = length / 2                     # => 2.5 m
```

### Advanced Precision

Handle high-precision calculations with BigDecimal arithmetic:

```crystal
# No floating-point rounding errors
precise = Unit::Weight.new(BigDecimal.new("0.1"), :kilogram)
result = precise + Unit::Weight.new(BigDecimal.new("0.2"), :kilogram)
result.value == BigDecimal.new("0.3")   # => true (exactly 0.3, not 0.30000000000000004)

# Very large numbers maintain precision
huge = Unit::Length.new(BigDecimal.new("1" + "0" * 50), :meter)
converted = huge.convert_to(:kilometer)  # Maintains full precision

# Scientific calculations with exact values
light_speed = Unit::Length.new(299792458, :meter)  # Exact value
astronomical_unit = Unit::Length.new(BigDecimal.new("149597870.7"), :kilometer)

# Round-trip conversions maintain precision
original = Unit::Weight.new(BigDecimal.new("123.456789"), :kilogram)
round_trip = original.convert_to(:pound).convert_to(:kilogram)
original == round_trip                   # => true (exact equality)
```

### Scientific Computing

Perfect for scientific and engineering applications requiring precision:

```crystal
# Physical constants with exact values
electron_mass = Unit::Weight.new(BigDecimal.new("9.1093837015e-31"), :kilogram)
proton_mass = Unit::Weight.new(BigDecimal.new("1.67262192369e-27"), :kilogram)

# Relativistic calculations
def lorentz_factor(velocity : Unit::Length, time_unit : Symbol = :second)
  c = Unit::Length.new(299792458, :meter)  # Speed of light
  v_over_c = velocity.convert_to(:meter).value / c.value
  1 / Math.sqrt(1 - v_over_c ** 2)
end

# Astronomical distances
au = Unit::Length.new(BigDecimal.new("149597870.7"), :kilometer)
light_year = Unit::Length.new(BigDecimal.new("9.4607304725808e12"), :kilometer)

distance_to_proxima = light_year * BigDecimal.new("4.24")
distance_in_au = distance_to_proxima.convert_to(:kilometer).value / au.value

# Chemical calculations with precise molar masses
water_molar_mass = Unit::Weight.new(BigDecimal.new("18.01528"), :gram)
avogadro = BigDecimal.new("6.02214076e23")
single_molecule_mass = water_molar_mass.value / avogadro
```

### Recipe and Cooking Applications

Ideal for culinary applications with fractional measurements:

```crystal
# Recipe scaling with fractions
original_flour = Unit::Parser.parse("2 1/4 cups", Unit::Volume)
scaled_flour = original_flour * BigDecimal.new("1.5")  # 1.5x recipe
# => 3.375 cups

# International recipe conversion
metric_flour = scaled_flour.convert_to(:milliliter)
# => 798.75 mL

# Ingredient substitutions
butter_volume = Unit::Volume.new(0.5, :cup)
butter_weight = butter_volume.convert_to(:milliliter).value * BigDecimal.new("0.911") # Butter density
butter_in_grams = Unit::Weight.new(butter_weight, :gram)

# Shopping list aggregation
recipe1_sugar = Unit::Parser.parse("1 1/2 cups", Unit::Volume) 
recipe2_sugar = Unit::Parser.parse("3/4 cup", Unit::Volume)
total_sugar = recipe1_sugar + recipe2_sugar  # => 2.25 cups

# Temperature handling (if Temperature type existed)
# oven_temp = Unit::Temperature.new(350, :fahrenheit)
# celsius_temp = oven_temp.convert_to(:celsius)  # => 176.67°C

# Nutritional calculations
flour_calories_per_cup = 455
total_flour_cups = scaled_flour.value.to_f
total_calories = total_flour_cups * flour_calories_per_cup
```

### Density Conversions

Convert between weight and volume measurements using density values:

```crystal
# Create density measurements
water_density = Unit::Density.new(1.0, :gram_per_milliliter)
flour_density = Unit::Density.new(0.593, :gram_per_milliliter)
honey_density = 1.42.g_per_ml  # Using numeric extensions

# Convert weight to volume
flour_weight = 200.grams
flour_volume = flour_weight.to_volume(flour_density)  # => ~337 mL

# Convert volume to weight
milk_volume = 250.milliliters
milk_weight = milk_volume.to_weight(milk_density)  # => ~258 g

# Use overloaded methods (value + unit) - no Density object needed
oil_volume = 250.grams.to_volume(0.92, :gram_per_milliliter)  # => ~272 mL
juice_weight = 1.cup.to_weight(1.03, :g_per_ml)              # => ~244 g

# Use explicit naming for clarity
butter_volume = 1.pound.volume_given(water_density)
honey_weight = 2.cups.weight_given(1.42, :gram_per_cubic_centimeter)

# Round-trip conversions maintain precision
original_weight = 500.grams
density = Unit::Density.new(0.8, :gram_per_milliliter)
volume = original_weight.to_volume(density)
final_weight = volume.to_weight(density)
original_weight == final_weight  # => true
```

#### **Density Units Supported**

**Metric Units:**
- `:gram_per_milliliter` (g/mL) - Base unit
- `:kilogram_per_liter` (kg/L) - Equivalent to g/mL
- `:gram_per_cubic_centimeter` (g/cm³) - Equivalent to g/mL
- `:kilogram_per_cubic_meter` (kg/m³) - 0.001 g/mL

**Imperial Units:**
- `:pound_per_gallon` (lb/gal) - 0.119826 g/mL
- `:pound_per_cubic_foot` (lb/ft³) - 0.016019 g/mL
- `:ounce_per_cubic_inch` (oz/in³) - 1.72999 g/mL

#### **Scientific Applications**

```crystal
# Buoyancy calculations
wood_density = Unit::Density.new(0.75, :gram_per_cubic_centimeter)  # Oak wood
water_density = Unit::Density.new(1.0, :gram_per_milliliter)

wood_volume = Unit::Volume.new(1000, :milliliter)  # 1000 mL = 1000 cm³
wood_weight = wood_volume.to_weight(wood_density)
water_displaced = wood_volume.to_weight(water_density)

if wood_weight < water_displaced
  puts "Wood floats! ✅"
else
  puts "Wood sinks! ❌"
end

# Material property analysis
aluminum_density = Unit::Density.new(2.70, :gram_per_cubic_centimeter)
aluminum_block = Unit::Volume.new(100, :milliliter)  # 100 mL = 100 cm³
aluminum_weight = aluminum_block.to_weight(aluminum_density)
strength_ratio = aluminum_weight.value / 100  # Weight per cm³

# Chemistry calculations
mercury_density = Unit::Density.new(13.534, :gram_per_cubic_centimeter)
mercury_volume = Unit::Volume.new(50, :milliliter)
mercury_weight = mercury_volume.to_weight(mercury_density)
puts "#{mercury_weight.format(precision: 1)} of mercury in 50mL"

# Baking applications with custom densities
flour_density = Unit::Density.new(0.593, :gram_per_milliliter)
sugar_density = Unit::Density.new(0.850, :gram_per_milliliter)

recipe_weight = 500.grams
flour_volume = recipe_weight.to_volume(flour_density)
sugar_volume = recipe_weight.to_volume(sugar_density)

puts "500g flour = #{flour_volume.humanize}"
puts "500g sugar = #{sugar_volume.humanize}"
```

## API

### Measurement Types

The library provides four core measurement types, each with comprehensive unit support:

#### **Unit::Weight** - Mass/Weight Measurements
- **Units**: `:gram` (base), `:kilogram`, `:milligram`, `:tonne`, `:pound`, `:ounce`, `:slug`
- **Aliases**: `g`, `kg`, `mg`, `t`, `lb`, `oz`
- **Unit Detection**: `.metric?` method to identify metric vs imperial units
- **Relationships**: Exact conversion factors (16 oz = 1 lb, 1000 g = 1 kg)

#### **Unit::Length** - Distance/Length Measurements  
- **Units**: `:meter` (base), `:centimeter`, `:millimeter`, `:kilometer`, `:inch`, `:foot`, `:yard`, `:mile`
- **Aliases**: `m`, `cm`, `mm`, `km`, `in`, `ft`, `yd`, `mi`
- **Standards**: NIST/ISO exact conversions (1 inch = 0.0254 meters exactly)
- **Relationships**: Imperial (12 in = 1 ft, 3 ft = 1 yd, 5280 ft = 1 mi)

#### **Unit::Volume** - Liquid Volume Measurements
- **Units**: `:liter` (base), `:milliliter`, `:gallon`, `:quart`, `:pint`, `:cup`, `:fluid_ounce`
- **Aliases**: `L`, `mL`, `gal`, `qt`, `pt`, `fl oz`
- **System**: US Liquid system with exact conversions (128 fl oz = 1 gal)
- **Precision**: Cooking measurements support exact fractions

#### **Unit::Density** - Density Measurements (Mass per Volume)
- **Units**: `:gram_per_milliliter` (base), `:kilogram_per_liter`, `:gram_per_cubic_centimeter`, `:kilogram_per_cubic_meter`, `:pound_per_gallon`, `:pound_per_cubic_foot`, `:ounce_per_cubic_inch`
- **Aliases**: `g_per_ml`, `kg_per_l`, `g_per_cc`, `kg_per_m3`, `lb_per_gal`, `lb_per_ft3`, `oz_per_in3`
- **System**: Both metric (g/mL base) and imperial units with exact conversions
- **Features**: Built-in material density constants, mass-volume conversion support

### Core Methods

All measurement types inherit from `Unit::Measurement(T, U)` and support:

#### **Construction Methods**
- `new(value : Number, unit : Symbol | Enum)` - Create measurement with symbol or enum
- `new(value : BigDecimal, unit)` - Create with exact precision
- `new(value : BigRational, unit)` - Create with rational numbers

#### **Conversion Methods**
- `convert_to(unit : Symbol) : Self` - Convert to different unit  
- `to(unit : Symbol) : Self` - Alias for convert_to
- `value : BigDecimal` - Get the numeric value with full precision
- `unit : Enum` - Get the unit enum value

#### **Arithmetic Operations**
- `+(other : Self) : Self` - Add measurements (converts to left operand's unit)
- `-(other : Self) : Self` - Subtract measurements
- `*(scalar : Number) : Self` - Multiply by scalar value
- `/(scalar : Number) : Self` - Divide by scalar value

#### **Density Conversion Operations**
- `weight.to_volume(density) : Volume` - Convert weight to volume using density
- `weight.to_volume(value, unit) : Volume` - Convert using density value+unit
- `weight.volume_given(density) : Volume` - Explicit naming alias
- `volume.to_weight(density) : Weight` - Convert volume to weight using density
- `volume.to_weight(value, unit) : Weight` - Convert using density value+unit
- `volume.weight_given(density) : Weight` - Explicit naming alias

#### **Comparison Operations**
- `==(other : Self) : Bool` - Equality with automatic unit conversion
- `<=>(other : Self) : Int32` - Spaceship operator for sorting
- `<`, `>`, `<=`, `>=` - All comparison operators with unit conversion
- `hash : UInt64` - Hash value (equivalent measurements have same hash)

#### **Formatting Methods**
- `to_s : String` - Default string representation
- `format(precision : Int32, unit_format : Symbol) : String` - Custom formatting
- `humanize : String` - Human-readable format with pluralization
- `inspect : String` - Debug representation showing type information

#### **Unit Information**
- `unit.symbol : String` - Short unit symbol (e.g., "kg", "ft")
- `unit.name : String` - Full unit name (e.g., "kilogram", "foot")  
- `unit.name(plural: true) : String` - Plural form (e.g., "kilograms", "feet")
- `unit.metric? : Bool` - Check if unit is metric system

### Parser

Advanced string parsing with natural language support:

```crystal
# Primary parsing method
Unit::Parser.parse(input : String, type : T.class) : T

# Supported formats:
Unit::Parser.parse("10.5 kg", Unit::Weight)           # Decimal values
Unit::Parser.parse("1 1/2 pounds", Unit::Weight)      # Mixed fractions
Unit::Parser.parse("3/4 cup", Unit::Volume)           # Simple fractions
Unit::Parser.parse("10kg", Unit::Weight)              # No spaces
Unit::Parser.parse("5.5 KILOGRAMS", Unit::Weight)     # Case insensitive
Unit::Parser.parse("  2.5  ft  ", Unit::Length)       # Extra whitespace
Unit::Parser.parse("1.5e3 g", Unit::Weight)           # Scientific notation
Unit::Parser.parse("1.0 g/mL", Unit::Density)        # Density measurements
Unit::Parser.parse("62.4 lb/ft³", Unit::Density)      # Imperial density
Unit::Parser.parse("0.92 g/cc", Unit::Density)        # Common variations
```

### Formatter

Flexible formatting with precision and style control:

```crystal
measurement.format(
  precision: Int32,     # Decimal places (0-10, clamped for safety)
  unit_format: Symbol   # :short for symbols, :long for full names
) : String

# Examples:
weight.format(precision: 2)                    # => "5.50 kg"
weight.format(unit_format: :long)              # => "5.5 kilogram"  
weight.format(precision: 0, unit_format: :long) # => "6 kilogram"
```

### Exceptions

Hierarchical exception system for comprehensive error handling:

- **`Unit::UnitError`** - Base class for all unit-related errors
- **`Unit::ConversionError`** - Unit conversion failures with context
- **`Unit::ParseError`** - String parsing errors with detailed messages  
- **`Unit::ValidationError`** - Measurement validation failures
- **`Unit::ArithmeticError`** - Mathematical operation errors (division by zero)

```crystal
begin
  Unit::Parser.parse("invalid", Unit::Weight)
rescue Unit::ParseError => e
  puts e.message  # "Could not parse 'invalid' as Weight"
end
```

## Integrations

### Avram ORM

Deep integration with Avram ORM provides type-safe database persistence:

```crystal
require "unit/integrations/avram"

class Product < BaseModel
  include Unit::Avram::ColumnExtensions
  
  table do
    # Creates virtual measurement attributes with value/unit column pairs
    measurement_column :weight, Weight, required: true
    measurement_column :dimensions_length, Length
    measurement_column :volume, Volume
  end
end
```

#### **Database Schema**
The `measurement_column` macro creates two database columns:
- `{name}_value : Numeric` - Stores the numeric value  
- `{name}_unit : String` - Stores the unit as string

#### **Model Features**
```crystal
product = Product.new
product.weight = Unit::Weight.new(2.5, :kilogram)

# Access methods
product.weight                    # => Unit::Weight instance
product.weight_value             # => BigDecimal("2.5") 
product.weight_unit              # => "kilogram"

# Unit conversion helpers  
product.weight_in(:pound)        # => Unit::Weight in pounds
product.length_in(:inch)         # => Unit::Length in inches

# String parsing setters (useful for forms)
product.weight_from_string = "5.5 lbs"  # Automatically parses and sets
```

#### **Migration Helpers**
```crystal
class AddMeasurementsToProducts < Avram::Migrator::Migration
  def migrate
    # Creates value/unit column pairs with proper types and constraints
    add_measurement_column :products, :weight, Weight, precision: 10, scale: 4
    add_measurement_column :products, :length, Length, required: false
    
    # Adds CHECK constraints for valid units and indexes for performance
    add_index :products, [:weight_value, :weight_unit]
  end
end
```

#### **Validation Extensions**  
Type-safe validations with automatic unit conversion:

```crystal
class SaveProduct < Product::SaveOperation
  include Unit::Avram::ValidationExtensions
  
  permit_columns weight, length
  
  def run
    # Validates measurement is within range (converts units automatically)
    validate_measurement_range weight, min: Unit::Weight.new(0.1, :kilogram),
                                       max: Unit::Weight.new(100, :kilogram)
    
    # Ensures positive values
    validate_measurement_positive weight
    
    # Restricts to specific units
    validate_measurement_unit weight, allowed: [:kilogram, :pound]
  end
end
```

### Lucky Framework

Seamless integration with Lucky web framework for forms and display:

```crystal
# In Lucky pages - automatic form field generation
form_for UpdateProduct do
  measurement_input weight, "Product Weight"
  measurement_input length, "Length"
end

# Generates select field for units and input for value
# <input name="weight_value" type="number" step="any">
# <select name="weight_unit">
#   <option value="kilogram">Kilogram</option>
#   <option value="pound">Pound</option>
# </select>

# Display measurements in pages
text weight.format(precision: 2, unit_format: :long)
text length.humanize
```

#### **Query Extensions**
Advanced database queries with automatic unit conversion:

```crystal
class ProductQuery < Product::BaseQuery
  include Unit::Avram::QueryExtensions
  
  # Find products within weight range (automatically converts units)
  def within_weight_range(min : Unit::Weight, max : Unit::Weight)
    with_weight_between(min, max)
  end
  
  # Find products matching specific unit
  def with_metric_weights
    with_weight_unit([:kilogram, :gram])
  end
  
  # Complex dimensional queries
  def fits_in_box(length : Unit::Length, width : Unit::Length, height : Unit::Length)
    where { |q| 
      q.length.lte(length.convert_to(:centimeter).value) &
      q.width.lte(width.convert_to(:centimeter).value) &
      q.height.lte(height.convert_to(:centimeter).value)
    }
  end
end

# Usage
heavy_products = ProductQuery.new.within_weight_range(
  Unit::Weight.new(10, :kilogram),
  Unit::Weight.new(50, :pound)  # Automatically converted for comparison
)
```

### JSON/YAML Serialization

Built-in serialization preserves precision and type information:

```crystal
weight = Unit::Weight.new(BigDecimal.new("5.123456789"), :kilogram)

# JSON serialization
json_string = weight.to_json
# => {"value":"5.123456789","unit":"kilogram"}

# JSON deserialization  
restored_weight = Unit::Weight.from_json(json_string)
restored_weight == weight  # => true (exact precision maintained)

# YAML serialization
yaml_string = weight.to_yaml
# => ---
# value: '5.123456789'
# unit: kilogram

# YAML deserialization
Unit::Weight.from_yaml(yaml_string)

# Works with collections
weights = [
  Unit::Weight.new(1, :kilogram),
  Unit::Weight.new(2, :pound)
]
weights.to_json  # Serializes entire array

# API-friendly for REST endpoints
class API::ProductsController < ApiAction
  def show
    json ProductSerializer.new(product)  # Measurements automatically serialized
  end
end
```

### Database Storage

Optimized storage strategies for different database systems:

#### **PostgreSQL Integration**
- **NUMERIC type**: Precise storage without floating-point errors
- **Enum types**: Efficient unit storage with constraints
- **JSONB support**: Flexible storage for measurements as JSON
- **Index optimization**: Composite indexes on value/unit pairs
- **Check constraints**: Database-level unit validation

```crystal
# PostgreSQL-specific optimizations
class CreateProducts < Avram::Migrator::Migration
  def migrate
    create_enum :weight_unit_enum, values: ["kilogram", "pound", "gram", "ounce"]
    
    create :products do
      # Efficient storage with enum type
      add weight_value : Numeric, precision: 10, scale: 4
      add weight_unit : WeightUnitEnum
      
      # Alternative: JSONB storage for flexibility
      add dimensions : JSON
    end
    
    # Optimized indexes
    add_index :products, [:weight_value, :weight_unit], name: "products_weight_idx"
  end
end
```

#### **SQLite Integration**  
- **TEXT storage**: Units stored as strings with validation
- **REAL storage**: Numeric values with precision considerations
- **JSON support**: Modern SQLite JSON functions

#### **MySQL Integration**
- **DECIMAL type**: Precise numeric storage  
- **ENUM type**: Efficient unit constraint storage
- **JSON type**: Native JSON column support (MySQL 5.7+)

## Advanced Features

### Phantom Type System

The library uses Crystal's advanced type system to provide compile-time safety through phantom types:

```crystal
# The Measurement class uses phantom types for safety
abstract class Unit::Measurement(T, U)
  # T is the phantom type (Weight, Length, Volume)
  # U is the unit enum type
end

# This prevents mixing measurement types at compile time
weights = Array(Unit::Weight).new          # Only accepts Weight measurements
weights << Unit::Weight.new(1, :kilogram)  # ✓ Valid

# This won't compile:
# weights << Unit::Length.new(1, :meter)   # Compile error!

# Function parameters are type-safe
def total_weight(items : Array(Unit::Weight)) : Unit::Weight
  items.sum { |item| item.convert_to(:kilogram) }
end

# Only accepts Weight arrays - Length arrays rejected at compile time
```

### BigDecimal Precision

All calculations use BigDecimal arithmetic to eliminate floating-point errors:

```crystal
# Exact decimal arithmetic
precise = Unit::Weight.new(BigDecimal.new("0.1"), :kilogram)
result = precise + Unit::Weight.new(BigDecimal.new("0.2"), :kilogram)
result.value == BigDecimal.new("0.3")  # => true (exactly 0.3)

# Contrast with floating-point errors
float_result = 0.1 + 0.2               # => 0.30000000000000004 (imprecise)

# Scientific precision maintained
avogadro = BigDecimal.new("6.02214076e23")
planck = BigDecimal.new("6.62607015e-34")

# Very large and very small numbers handled precisely
huge_distance = Unit::Length.new(BigDecimal.new("1" + "0" * 100), :meter)
tiny_mass = Unit::Weight.new(BigDecimal.new("1e-50"), :kilogram)

# Round-trip conversions maintain exact precision
original = Unit::Weight.new(BigDecimal.new("123.456789012345"), :kilogram)
converted = original.convert_to(:pound).convert_to(:ounce).convert_to(:kilogram)
original == converted  # => true (exact equality preserved)
```

### Custom Validation

Extensible validation system for business rules and constraints:

```crystal
# In Avram models with custom validations
class Product < BaseModel
  include Unit::Avram::ValidationExtensions
  
  # Built-in measurement validations
  def validate_measurements
    validate_measurement_positive weight
    validate_measurement_range weight, 
      min: Unit::Weight.new(0.01, :kilogram),
      max: Unit::Weight.new(1000, :kilogram)
    
    # Custom business logic validation
    validate_shipping_constraints
  end
  
  private def validate_shipping_constraints
    # Dimensional weight calculation for shipping
    if dimensional_weight > actual_weight
      weight.add_error "Dimensional weight (#{dimensional_weight.humanize}) exceeds actual weight"
    end
    
    # International shipping restrictions
    if weight.convert_to(:kilogram).value > 30
      weight.add_error "Exceeds international shipping weight limit (30kg)"
    end
  end
  
  private def dimensional_weight
    # Calculate dimensional weight (length × width × height ÷ 5000)
    volume_cm3 = length_cm.value * width_cm.value * height_cm.value
    dimensional_kg = volume_cm3 / 5000
    Unit::Weight.new(dimensional_kg, :kilogram)
  end
end

# Custom validator classes
class WeightRangeValidator
  def initialize(@min : Unit::Weight, @max : Unit::Weight)
  end
  
  def valid?(measurement : Unit::Weight) : Bool
    measurement >= @min && measurement <= @max
  end
  
  def error_message(measurement : Unit::Weight) : String
    "Weight #{measurement.humanize} must be between #{@min.humanize} and #{@max.humanize}"
  end
end
```

### Performance Optimizations

The library includes several performance optimizations:

#### **Same-Unit Optimization**
```crystal
# When converting to the same unit, returns self (no allocation)
weight = Unit::Weight.new(5, :kilogram)
same_weight = weight.convert_to(:kilogram)
same_weight.same?(weight)  # => true (same object reference)
```

#### **Base Unit Normalization**
```crystal
# Conversions go through base unit for accuracy and performance
# All Weight conversions normalize to grams internally
# All Length conversions normalize to meters internally
# All Volume conversions normalize to liters internally

# This ensures consistent conversion paths and caching opportunities
```

#### **Immutable Design Benefits**
```crystal
# Immutable objects are thread-safe and can be cached
weight = Unit::Weight.new(5, :kilogram)

# Operations return new objects, original never changes
doubled = weight * 2
weight.value  # => Still BigDecimal("5") - unchanged

# Thread-safe usage
spawn { puts weight.convert_to(:pound) }  # Safe - no mutation
spawn { puts weight.format(precision: 2) }  # Safe - no mutation
```

#### **Memory Efficiency**
```crystal
# BigDecimal values are efficiently managed
# Unit enums are lightweight value types
# String representations are computed on-demand

# Object pooling for common values could be added in future versions
```

## Examples

The library includes comprehensive examples demonstrating real-world usage:

### **Basic Usage** (`examples/basic_usage.cr`)
- Creating measurements with different numeric types
- Unit conversions and arithmetic operations
- Comparison and sorting operations
- Type safety demonstrations

### **String Parsing** (`examples/parser_demo.cr`)  
- Natural language parsing with fractions
- Error handling for invalid inputs
- Case-insensitive and whitespace-flexible parsing
- Unit alias support

### **Formatting** (`examples/formatting_demo.cr`)
- Precision control and unit format options
- Humanization with pluralization
- Special case handling (negatives, zeros)

### **Scientific Computing** (`examples/scientific.cr`)
- Physical constants and calculations
- Astronomical measurements  
- Chemical calculations with precise molecular masses
- Relativistic physics calculations

### **Cooking Applications** (`examples/cooking.cr`)
- Recipe scaling with fractional measurements
- International unit conversions for recipes
- Ingredient substitution calculations
- Shopping list aggregation

### **Avram Integration** (`examples/avram_example.cr`)
- Database model setup with measurement columns
- Query operations with unit conversions
- Validation scenarios
- Form handling examples

### **Lucky Framework** (`examples/lucky_app/`)
- Complete web application example
- Product catalog with measurements
- Form inputs and validation
- Business logic calculations
- User interface examples

Each example includes detailed comments explaining the concepts and can be run independently to explore the library's capabilities.

## Contributing

We welcome contributions to make the Unit library even better! Here's how you can help:

### Getting Started

1. Fork the repository (<https://github.com/ButterbaseApp/unit/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Make your changes with comprehensive tests
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create a new Pull Request

### Development Environment

```bash
# Install dependencies
shards install

# Run the full test suite
crystal spec

# Run specific test files
crystal spec spec/unit/measurement_spec.cr
crystal spec spec/unit/parser_spec.cr

# Run code formatting
crystal tool format

# Run linter
./bin/ameba

# Generate documentation
crystal docs
```

### Contribution Guidelines

**What We're Looking For:**
- New measurement types (Temperature, Area, Pressure, etc.)
- Additional unit support for existing types
- Performance improvements and optimizations
- Documentation improvements and examples
- Bug fixes with comprehensive test coverage
- Framework integrations (Granite, Lucky enhancements, etc.)
- Additional density constants for common materials
- Enhanced density string parsing (more unit variations)

**Code Quality Standards:**
- All new code must include comprehensive specs
- Follow existing code style and patterns
- Use BigDecimal for precision-critical calculations
- Maintain compile-time type safety
- Include documentation for public APIs
- Add examples for new features

**Testing Requirements:**
- Unit tests for all new functionality
- Integration tests for framework features
- Edge case testing (large numbers, precision limits)
- Error condition testing
- Performance regression testing

**Documentation:**
- Update README for new features
- Add inline documentation for public methods
- Include practical examples
- Update API documentation

### Areas for Contribution

**High Priority:**
- Temperature measurement type with Celsius, Fahrenheit, Kelvin
- Area measurement type (square meters, acres, etc.)
- Pressure measurement type (Pascal, PSI, bar, etc.)
- Additional volume units (Imperial pints, quarts vs US)
- Performance benchmarks and optimizations

**Medium Priority:**
- Granite ORM integration
- More comprehensive Lucky form helpers
- Additional database type support
- Internationalization for unit names
- More cooking/recipe specific units

**Documentation & Examples:**
- Real-world application tutorials
- Performance best practices guide
- Migration guide from other unit libraries
- Video tutorials or presentations

### Questions and Support

- **Documentation**: Check the comprehensive API documentation above
- **Examples**: Review the `examples/` directory for usage patterns
- **Issues**: Open an issue on GitHub for bugs or feature requests
- **Discussions**: Use GitHub Discussions for questions and ideas
- **Community**: Join Crystal community channels for general help

### Code of Conduct

Please note that this project follows the [Crystal Code of Conduct](https://github.com/crystal-lang/crystal/blob/master/CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Built with ❤️ for the Crystal community**

The Unit library represents hundreds of hours of development focused on creating the most robust, type-safe, and precise measurement handling system for Crystal applications. Whether you're building scientific software, e-commerce platforms, recipe applications, or IoT systems, Unit provides the foundation for reliable measurement handling with Crystal's compile-time guarantees and runtime performance.
