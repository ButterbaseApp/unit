# Optional numeric extensions for convenient measurement creation
#
# This file extends Crystal's built-in numeric types (Int, Float, BigDecimal, BigInt)
# with convenient methods for creating Unit measurements. Include this file only
# if you want the convenient syntax like `5.grams` or `1.2.kg`.
#
# ## Usage
#
# ```
# require "unit"
# require "unit/extensions" # Optional - enables convenient syntax
#
# # With extensions enabled:
# weight = 5.grams    # => Unit::Weight.new(5, :gram)
# length = 1.2.meters # => Unit::Length.new(1.2, :meter)
# volume = 500.ml     # => Unit::Volume.new(500, :milliliter)
#
# # Without extensions (always available):
# weight = Unit::Weight.new(5, :gram)
# length = Unit::Length.new(1.2, :meter)
# volume = Unit::Volume.new(500, :milliliter)
# ```
#
# ## Supported Numeric Types
#
# All Crystal numeric types are extended:
# - Int8, Int16, Int32, Int64, Int128, UInt8, UInt16, UInt32, UInt64, UInt128
# - Float32, Float64
# - BigDecimal, BigInt, BigRational
#
# ## Method Categories
#
# ### Weight Methods
# - `.grams`, `.gram`, `.g` - Creates Weight in grams
# - `.kilograms`, `.kilogram`, `.kg` - Creates Weight in kilograms
# - `.milligrams`, `.milligram`, `.mg` - Creates Weight in milligrams
# - `.tonnes`, `.tonne`, `.t` - Creates Weight in tonnes
# - `.pounds`, `.pound`, `.lb` - Creates Weight in pounds
# - `.ounces`, `.ounce`, `.oz` - Creates Weight in ounces
# - `.slugs`, `.slug` - Creates Weight in slugs
#
# ### Length Methods
# - `.meters`, `.meter`, `.m` - Creates Length in meters
# - `.centimeters`, `.centimeter`, `.cm` - Creates Length in centimeters
# - `.millimeters`, `.millimeter`, `.mm` - Creates Length in millimeters
# - `.kilometers`, `.kilometer`, `.km` - Creates Length in kilometers
# - `.inches`, `.inch`, `.in` - Creates Length in inches
# - `.feet`, `.foot`, `.ft` - Creates Length in feet
# - `.yards`, `.yard`, `.yd` - Creates Length in yards
# - `.miles`, `.mile`, `.mi` - Creates Length in miles
#
# ### Volume Methods
# - `.liters`, `.liter`, `.l` - Creates Volume in liters
# - `.milliliters`, `.milliliter`, `.ml` - Creates Volume in milliliters
# - `.gallons`, `.gallon`, `.gal` - Creates Volume in gallons
# - `.quarts`, `.quart`, `.qt` - Creates Volume in quarts
# - `.pints`, `.pint`, `.pt` - Creates Volume in pints
# - `.cups`, `.cup` - Creates Volume in cups
# - `.fluid_ounces`, `.fluid_ounce`, `.fl_oz` - Creates Volume in fluid ounces

require "./measurements/weight"
require "./measurements/length"
require "./measurements/volume"

module Unit
  # Base module for all numeric extensions
  #
  # This module combines all measurement-specific numeric extension modules
  # and provides a single point to extend all numeric types in Crystal.
  module AllNumericExtensions
    include Weight::NumericExtensions
    include Length::NumericExtensions
    include Volume::NumericExtensions
  end
end

# Extend all Crystal numeric types with measurement creation methods
{% for type in [Int8, Int16, Int32, Int64, Int128, UInt8, UInt16, UInt32, UInt64, UInt128] %}
  struct {{ type }}
    include Unit::AllNumericExtensions
  end
{% end %}

{% for type in [Float32, Float64] %}
  struct {{ type }}
    include Unit::AllNumericExtensions
  end
{% end %}

{% for type in [BigDecimal, BigInt, BigRational] %}
  struct {{ type }}
    include Unit::AllNumericExtensions
  end
{% end %}
