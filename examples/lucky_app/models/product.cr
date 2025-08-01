# Example Product model with Unit measurements
require "unit/integrations/avram"

class Product < BaseModel
  include Unit::Avram::ColumnExtensions

  table do
    primary_key id : Int64 # ameba:disable Lint/UselessAssign

    # Basic product information
    column name : String         # ameba:disable Lint/UselessAssign
    column description : String? # ameba:disable Lint/UselessAssign
    column sku : String          # ameba:disable Lint/UselessAssign

    # Measurement columns - creates value and unit columns for each
    measurement_column :weight, Weight, required: true, indexed: true
    measurement_column :length, Length, required: true
    measurement_column :width, Length, required: true
    measurement_column :height, Length, required: true

    # Pricing and inventory
    column price_cents : Int32    # ameba:disable Lint/UselessAssign
    column stock_quantity : Int32 # ameba:disable Lint/UselessAssign

    timestamps
  end

  # Calculate volume from dimensions
  def volume : Unit::Volume?
    return nil unless length && width && height

    # Convert all to meters for calculation
    length_val = length
    width_val = width
    height_val = height
    return nil unless length_val && width_val && height_val

    l = length_val.convert_to(:meter).value
    w = width_val.convert_to(:meter).value
    h = height_val.convert_to(:meter).value

    # Calculate cubic meters, then convert to liters
    cubic_meters = l * w * h
    liters = cubic_meters * BigDecimal.new("1000")

    Unit::Volume.new(liters, :liter)
  end

  # Calculate dimensional weight for shipping (in kg)
  # Using standard divisor of 5000 for kg/cm³
  def dimensional_weight : Unit::Weight
    return weight unless length && width && height

    # Convert to centimeters
    length_val = length
    width_val = width
    height_val = height
    return weight unless length_val && width_val && height_val

    l = length_val.convert_to(:centimeter).value
    w = width_val.convert_to(:centimeter).value
    h = height_val.convert_to(:centimeter).value

    # Calculate dimensional weight
    dim_weight_kg = (l * w * h) / BigDecimal.new("5000")
    dim_weight = Unit::Weight.new(dim_weight_kg, :kilogram)

    # Return the greater of actual or dimensional weight
    weight > dim_weight ? weight : dim_weight
  end

  # Get shipping weight (greater of actual or dimensional)
  def shipping_weight : Unit::Weight
    dimensional_weight
  end

  # Check if oversized for shipping
  def oversized_for_shipping? : Bool
    return false unless length && width && height

    # Check if any dimension exceeds limits
    max_length = Unit::Length.new(150, :centimeter)
    max_width = Unit::Length.new(100, :centimeter)
    max_height = Unit::Length.new(100, :centimeter)
    max_weight = Unit::Weight.new(30, :kilogram)

    length_val = length
    width_val = width
    height_val = height
    return false unless length_val && width_val && height_val

    length_val > max_length ||
      width_val > max_width ||
      height_val > max_height ||
      weight > max_weight
  end

  # Format price from cents
  def price : Float64
    price_cents / 100.0
  end

  # Check if in stock
  def in_stock? : Bool
    stock_quantity > 0
  end

  # Display dimensions in preferred format
  def dimensions_string(unit : Symbol = :centimeter) : String
    return "N/A" unless length && width && height

    length_val = length
    width_val = width
    height_val = height
    return "N/A" unless length_val && width_val && height_val

    l = length_val.to(unit).format(precision: 1)
    w = width_val.to(unit).format(precision: 1)
    h = height_val.to(unit).format(precision: 1)

    "#{l} × #{w} × #{h}"
  end
end
