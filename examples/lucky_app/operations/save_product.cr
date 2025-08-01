# Example SaveProduct operation with Unit validation
require "unit/integrations/avram"

class SaveProduct < Product::SaveOperation
  include Unit::Avram::ValidationExtensions
  
  # Permit the columns we want to allow users to set
  permit_columns name, description, sku, price_cents, stock_quantity
  
  # Custom attributes for parsing measurement strings
  attribute weight_string : String?
  attribute length_string : String?
  attribute width_string : String?
  attribute height_string : String?
  attribute weight_unit : String?
  attribute length_unit : String?
  
  before_save do
    parse_measurements
    validate_required_fields
    validate_measurements
    validate_sku_format
    calculate_shipping_class
  end
  
  private def parse_measurements
    # Parse weight from string if provided
    if weight_str = weight_string.value
      begin
        self.weight = Unit::Parser.parse(weight_str, Unit::Weight)
      rescue ex : ArgumentError
        weight.add_error("is invalid: #{ex.message}")
      end
    elsif weight_val = weight.value
      # Already have a weight object
    elsif weight_unit_val = weight_unit.value
      # Try to create from form inputs
      # This would come from separate value/unit form fields
    end
    
    # Parse dimensions
    parse_dimension(:length, length_string.value)
    parse_dimension(:width, width_string.value)
    parse_dimension(:height, height_string.value)
  end
  
  private def parse_dimension(field : Symbol, value : String?)
    return unless value
    
    begin
      parsed = Unit::Parser.parse(value, Unit::Length)
      case field
      when :length then self.length = parsed
      when :width  then self.width = parsed
      when :height then self.height = parsed
      end
    rescue ex : ArgumentError
      case field
      when :length then length.add_error("is invalid: #{ex.message}")
      when :width  then width.add_error("is invalid: #{ex.message}")
      when :height then height.add_error("is invalid: #{ex.message}")
      end
    end
  end
  
  private def validate_required_fields
    validate_required name
    validate_required sku
    validate_required price_cents
    
    # Custom validation messages for measurements
    validate_required weight, message: "is required for shipping calculations"
    validate_required length, message: "is required for packaging"
    validate_required width, message: "is required for packaging"
    validate_required height, message: "is required for packaging"
  end
  
  private def validate_measurements
    # Validate positive values
    validate_measurement_positive :weight
    validate_measurement_positive :length
    validate_measurement_positive :width  
    validate_measurement_positive :height
    
    # Validate reasonable ranges
    max_weight = Unit::Weight.new(1000, :kilogram)
    validate_measurement_max :weight, max_weight, 
      message: "exceeds maximum shippable weight"
    
    max_dimension = Unit::Length.new(500, :centimeter)
    validate_measurement_max :length, max_dimension
    validate_measurement_max :width, max_dimension
    validate_measurement_max :height, max_dimension
    
    # Ensure metric units for internal storage (optional)
    validate_measurement_unit :weight, 
      [Unit::Weight::Unit::Kilogram, Unit::Weight::Unit::Gram],
      message: "must be in metric units (kg or g)"
  end
  
  private def validate_sku_format
    return if sku.value.nil?
    
    sku_val = sku.value.not_nil!
    unless sku_val.matches?(/^[A-Z0-9\-]{6,20}$/)
      sku.add_error("must be 6-20 characters, uppercase letters, numbers, and hyphens only")
    end
  end
  
  private def calculate_shipping_class
    # This would set a shipping class based on weight/dimensions
    # For example: small, medium, large, oversized
  end
  
  # Helper method to set weight from value and unit
  def set_weight_from_form(value : String, unit : String)
    begin
      numeric_value = BigDecimal.new(value)
      unit_enum = parse_weight_unit(unit)
      self.weight = Unit::Weight.new(numeric_value, unit_enum)
    rescue ex
      weight.add_error("is invalid")
    end
  end
  
  private def parse_weight_unit(unit : String) : Unit::Weight::Unit
    case unit.downcase
    when "kg", "kilogram", "kilograms"
      Unit::Weight::Unit::Kilogram
    when "g", "gram", "grams"
      Unit::Weight::Unit::Gram
    when "lb", "pound", "pounds"
      Unit::Weight::Unit::Pound
    when "oz", "ounce", "ounces"
      Unit::Weight::Unit::Ounce
    else
      raise ArgumentError.new("Unknown weight unit: #{unit}")
    end
  end
  
  # Custom validation for business rules
  private def validate_minimum_weight
    return unless weight_value = weight.value
    
    min_weight = Unit::Weight.new(10, :gram)
    if weight_value < min_weight
      weight.add_error("must be at least #{min_weight.humanize}")
    end
  end
end