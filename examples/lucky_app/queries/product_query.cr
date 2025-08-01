# Example ProductQuery with Unit-aware filtering
require "unit/integrations/avram"

class ProductQuery < Product::BaseQuery
  include Unit::Avram::QueryExtensions

  # Generate query methods for measurements
  measurement_query_methods :weight, Weight
  measurement_query_methods :length, Length
  measurement_query_methods :width, Length
  measurement_query_methods :height, Length

  # Find products within weight range
  def within_weight_range(min : Unit::Weight, max : Unit::Weight)
    with_weight_between(min, max)
  end

  # Find products that fit in a box
  def fits_in_box(box_length : Unit::Length, box_width : Unit::Length, box_height : Unit::Length)
    # Products must fit in at least one orientation
    # This is simplified - real implementation would check all orientations
    with_length_less_than(box_length)
      .with_width_less_than(box_width)
      .with_height_less_than(box_height)
  end

  # Find lightweight products
  def lightweight(max_weight : Unit::Weight = Unit::Weight.new(1, :kilogram))
    with_weight_less_than(max_weight)
  end

  # Find heavy products
  def heavyweight(min_weight : Unit::Weight = Unit::Weight.new(10, :kilogram))
    with_weight_greater_than(min_weight)
  end

  # Find products by shipping class
  def standard_shipping
    # Standard shipping: under 30kg and fits in 100x60x60cm box
    max_weight = Unit::Weight.new(30, :kilogram)
    max_length = Unit::Length.new(100, :centimeter)
    max_width = Unit::Length.new(60, :centimeter)
    max_height = Unit::Length.new(60, :centimeter)

    with_weight_less_than(max_weight)
      .with_length_less_than(max_length)
      .with_width_less_than(max_width)
      .with_height_less_than(max_height)
  end

  # Find oversized products
  def oversized
    # Any dimension over 150cm or weight over 30kg
    large_dimension = Unit::Length.new(150, :centimeter)
    heavy_weight = Unit::Weight.new(30, :kilogram)

    where do
      raw("length_value > ? OR width_value > ? OR height_value > ? OR weight_value > ?",
        [large_dimension.value, large_dimension.value, large_dimension.value,
         heavy_weight.to(:gram).value])
    end
  end

  # Order by weight (lightest first)
  def order_by_weight_asc
    order_by(weight_value: :asc)
  end

  # Order by weight (heaviest first)
  def order_by_weight_desc
    order_by(weight_value: :desc)
  end

  # Order by volume (calculated)
  def order_by_volume_asc
    # Order by length * width * height
    order_by(Avram::OrderBy::Raw.new("length_value * width_value * height_value", :asc))
  end

  # Complex query: Find products for international shipping
  def suitable_for_international_shipping(destination_country : String)
    case destination_country
    when "US", "CA", "MX"
      # North America - up to 50kg
      max_weight = Unit::Weight.new(50, :kilogram)
    when "EU", "UK"
      # Europe - up to 30kg
      max_weight = Unit::Weight.new(30, :kilogram)
    else
      # Rest of world - up to 20kg
      max_weight = Unit::Weight.new(20, :kilogram)
    end

    # Must not be oversized and within weight limit
    with_weight_less_than(max_weight)
      .with_length_less_than(Unit::Length.new(120, :centimeter))
      .in_stock
  end

  # Scope to in-stock items
  def in_stock
    stock_quantity.gt(0)
  end

  # Search with measurements
  def search(term : String)
    query = name.ilike("%#{term}%")
      .or(&.description.ilike("%#{term}%"))
      .or(&.sku.ilike("%#{term}%"))

    # Also search by weight if it looks like a weight
    if weight = try_parse_weight(term)
      # Find products within 10% of the specified weight
      min = Unit::Weight.new(weight.value * BigDecimal.new("0.9"), weight.unit)
      max = Unit::Weight.new(weight.value * BigDecimal.new("1.1"), weight.unit)
      query.or { with_weight_between(min, max) }
    else
      query
    end
  end

  private def try_parse_weight(term : String) : Unit::Weight?
    Unit::Parser.parse(term, Unit::Weight)
  rescue
    nil
  end

  # Aggregate queries
  def total_weight : Unit::Weight?
    results = exec_scalar(&.select_sum(weight_value))
    return nil unless results

    # Assume all weights are stored in grams
    Unit::Weight.new(results, :gram)
  end

  def average_weight : Unit::Weight?
    results = exec_scalar(&.select_average(weight_value))
    return nil unless results

    Unit::Weight.new(results, :gram)
  end
end
