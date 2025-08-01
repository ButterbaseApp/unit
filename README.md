# unit

[![GitHub release](https://img.shields.io/github/release/watzon/unit.svg)](https://github.com/watzon/unit/releases)
[![Build Status](https://github.com/watzon/unit/workflows/CI/badge.svg)](https://github.com/watzon/unit/actions)
[![Crystal Version](https://img.shields.io/badge/crystal-%3E%3D1.0.0-brightgreen.svg)](https://crystal-lang.org/)
[![License](https://img.shields.io/github/license/watzon/unit.svg)](https://github.com/watzon/unit/blob/main/LICENSE)

Type-safe, compile-time unit conversions for Crystal with zero runtime overhead.

## Table of Contents

- [Background](#background)
- [Install](#install)
- [Usage](#usage)
  - [Basic Conversions](#basic-conversions)
  - [Arithmetic Operations](#arithmetic-operations)
  - [String Parsing](#string-parsing)
  - [Formatting](#formatting)
  - [Comparison and Equality](#comparison-and-equality)
  - [Type Safety](#type-safety)
- [API](#api)
- [Integration](#integration)
  - [Lucky/Avram](#luckyavram)
  - [JSON/YAML](#jsonyaml)
- [Contributing](#contributing)
- [License](#license)

## Background

The Unit library provides a robust, type-safe system for handling measurements and unit conversions in Crystal applications. It was built to address common challenges in working with measurements:

- **Type Safety**: Prevent mixing incompatible units at compile time (can't add meters to kilograms)
- **Zero Runtime Overhead**: All type checking happens at compile time using Crystal's type system
- **High Precision**: Uses `BigDecimal` internally to maintain precision across conversions
- **Extensible**: Easy to add new measurement types and units
- **Framework Integration**: Built-in support for Lucky/Avram ORM with database persistence

Key features:
- Compile-time type safety using phantom types
- Support for Weight, Length, and Volume measurements (more coming soon)
- Arithmetic operations with automatic unit conversion
- String parsing and formatting with multiple output styles
- Full Avram/Lucky integration for database persistence
- JSON/YAML serialization support

## Install

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     unit:
       github: watzon/unit
   ```

2. Run `shards install`

## Usage

```crystal
require "unit"
```

### Basic Conversions

Create measurements and convert between units:

```crystal
# Create measurements
weight = Unit::Weight.new(5.5, :kilogram)
length = Unit::Length.new(100, :centimeter)
volume = Unit::Volume.new(2, :liter)

# Convert to different units
pounds = weight.convert_to(:pound)      # => 12.125 lbs
meters = length.convert_to(:meter)      # => 1.0 m
gallons = volume.convert_to(:gallon)    # => 0.528 gal

# Use the convenient 'to' alias
inches = length.to(:inch)               # => 39.37 in
```

### Arithmetic Operations

Perform arithmetic with automatic unit conversion:

```crystal
# Addition (converts to first operand's unit)
total_weight = Unit::Weight.new(5, :kilogram) + Unit::Weight.new(10, :pound)
# => 9.54 kg

# Subtraction
difference = Unit::Length.new(2, :meter) - Unit::Length.new(50, :centimeter)
# => 1.5 m

# Multiplication by scalar
double_weight = weight * 2              # => 11.0 kg
half_length = length / 2                # => 50.0 cm

# Note: Multiplication of measurements returns the scalar value
area = length.value * width.value       # Returns BigDecimal, not a measurement
```

### String Parsing

Parse measurements from strings with support for various formats:

```crystal
# Parse decimal values
weight = Unit::Parser.parse("10.5 kg", Unit::Weight)
length = Unit::Parser.parse("5.25 meters", Unit::Length)

# Parse fractions
weight = Unit::Parser.parse("1 1/2 pounds", Unit::Weight)
volume = Unit::Parser.parse("2 3/4 cups", Unit::Volume)

# Parse with unit aliases
weight = Unit::Parser.parse("10 kilos", Unit::Weight)      # "kilos" -> :kilogram
length = Unit::Parser.parse("6 ft", Unit::Length)          # "ft" -> :foot

# Handle different spacing
Unit::Parser.parse("10kg", Unit::Weight)                   # No space
Unit::Parser.parse("10 kg", Unit::Weight)                  # With space
Unit::Parser.parse("10   kg", Unit::Weight)                # Multiple spaces
```

### Formatting

Format measurements for display:

```crystal
weight = Unit::Weight.new(5.5, :kilogram)

# Default formatting
weight.to_s                    # => "5.5 kg"

# Custom precision
weight.format(precision: 2)    # => "5.50 kg"
weight.format(precision: 0)    # => "6 kg"

# Humanized output with pluralization
weight.humanize                # => "5.5 kilograms"
Unit::Weight.new(1, :kilogram).humanize    # => "1 kilogram"

# Format with unit symbols
weight.format(unit_format: :symbol)        # => "5.5 kg"
weight.format(unit_format: :name)          # => "5.5 kilogram"
```

### Comparison and Equality

Compare measurements across different units:

```crystal
# Equality checks (automatic conversion)
kg = Unit::Weight.new(1, :kilogram)
g = Unit::Weight.new(1000, :gram)
kg == g                        # => true

# Comparisons
heavy = Unit::Weight.new(100, :kilogram)
light = Unit::Weight.new(10, :pound)
heavy > light                  # => true

# Sorting works naturally
weights = [
  Unit::Weight.new(5, :kilogram),
  Unit::Weight.new(10, :pound),
  Unit::Weight.new(1000, :gram)
]
weights.sort                   # Sorted by actual weight, not numeric value
```

### Type Safety

The library prevents invalid operations at compile time:

```crystal
weight = Unit::Weight.new(10, :kilogram)
length = Unit::Length.new(5, :meter)

# This won't compile - can't add different measurement types
# total = weight + length  # Compile error!

# This won't compile - can't compare different types
# weight > length          # Compile error!

# But you can multiply by scalars
doubled = weight * 2       # => 20 kg (valid)
```

## API

### Measurement Types

- `Unit::Weight` - Mass measurements (kilogram, pound, ounce, etc.)
- `Unit::Length` - Distance measurements (meter, foot, inch, etc.)
- `Unit::Volume` - Liquid volume measurements (liter, gallon, cup, etc.)

### Core Methods

All measurement types support:

- `new(value : Number, unit : Unit)` - Create a measurement
- `convert_to(unit : Unit)` - Convert to another unit
- `to(unit : Unit)` - Alias for convert_to
- `value : BigDecimal` - Get the numeric value
- `unit : Unit` - Get the unit enum value
- `+`, `-`, `*`, `/` - Arithmetic operations
- `==`, `<`, `>`, `<=`, `>=` - Comparison operations
- `to_s`, `format`, `humanize` - Formatting methods

### Parser

- `Unit::Parser.parse(string : String, type : T.class)` - Parse a measurement from a string

### Exceptions

- `Unit::ConversionError` - Raised when conversions fail
- `Unit::ParseError` - Raised when parsing fails
- `Unit::ValidationError` - Raised when validation fails

## Integration

### Lucky/Avram

The library includes full Avram ORM integration for Lucky applications:

```crystal
require "unit/integrations/avram"

class Product < BaseModel
  include Unit::Avram::ColumnExtensions
  
  table do
    measurement_column :weight, Weight, required: true
    measurement_column :length, Length
  end
end

# In operations
class SaveProduct < Product::SaveOperation
  permit_columns weight, length
end

# Usage
SaveProduct.create!(
  weight: Unit::Weight.new(2.5, :kilogram),
  length: Unit::Length.new(30, :centimeter)
)
```

See [docs/avram-integration.md](docs/avram-integration.md) for detailed Avram integration guide.

### JSON/YAML

Built-in serialization support:

```crystal
weight = Unit::Weight.new(5.5, :kilogram)

# JSON
weight.to_json  # => {"value":"5.5","unit":"kilogram"}

# YAML
weight.to_yaml  # => "---\nvalue: '5.5'\nunit: kilogram\n"

# Deserialize
Unit::Weight.from_json(%({"value":"5.5","unit":"kilogram"}))
Unit::Weight.from_yaml("value: '5.5'\nunit: kilogram")
```

## Contributing

1. Fork it (<https://github.com/watzon/unit/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

### Development

```bash
# Run tests
crystal spec

# Run code formatting
crystal tool format

# Run linter
./bin/ameba
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
