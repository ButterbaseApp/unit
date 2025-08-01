module Unit
  # Provides string formatting capabilities for measurements
  #
  # This module adds various formatting methods to measurements for
  # displaying values in different formats and styles.
  #
  # ## Formatting Options
  #
  # - **Precision**: Control decimal places (0-10)
  # - **Unit Format**: Short (:short) or long (:long) unit names
  # - **Humanization**: Natural language output with pluralization
  # - **Smart Formatting**: Automatic whole number detection
  #
  # ## Examples
  #
  # ```crystal
  # weight = Weight.new(10.5, Weight::Unit::Kilogram)
  # weight.format                    # => "10.50 kilogram"
  # weight.format(precision: 1)      # => "10.5 kilogram" 
  # weight.format(unit_format: :short) # => "10.50 kg"
  # weight.humanize                  # => "10.5 kilograms"
  # ```
  module Formatter
    # Writes the measurement to an IO stream
    #
    # Uses a smart format that shows minimal decimal places
    # but ensures integers display with .0 for consistency
    def to_s(io : IO) : Nil
      io << to_s_legacy_format
    end
    
    # Legacy format for backward compatibility
    # Shows .0 for integers, minimal decimals otherwise
    private def to_s_legacy_format : String
      value_str = if @value == @value.to_i
                    # For integers, show .0 to match expected behavior
                    "#{@value.to_i}.0"
                  else
                    # For decimals, remove trailing zeros but keep at least one decimal
                    formatted = @value.to_s
                    if formatted.includes?('.')
                      formatted = formatted.rstrip('0')
                      formatted = formatted.rstrip('.') + ".0" if formatted.ends_with?('.')
                    end
                    formatted
                  end
      
      unit_string = @unit.to_s.underscore.gsub('_', ' ')
      "#{value_str} #{unit_string}"
    end
    
    # Returns a formatted string representation of the measurement
    #
    # ## Parameters
    #
    # - **precision**: Number of decimal places (0-10, default: 2)
    # - **unit_format**: Format style for units (:short or :long, default: :long)
    #
    # ## Examples
    #
    # ```crystal
    # measurement.format                          # => "10.50 kilogram"
    # measurement.format(precision: 0)            # => "11 kilogram"
    # measurement.format(precision: 3)            # => "10.500 kilogram"
    # measurement.format(unit_format: :short)     # => "10.50 kg"
    # measurement.format(precision: 1, unit_format: :short) # => "10.5 kg"
    # ```
    def format(precision : Int32 = 2, unit_format : Symbol = :long) : String
      formatted_value = format_value(precision)
      unit_string = format_unit(unit_format)
      "#{formatted_value} #{unit_string}"
    end
    
    # Returns a human-readable string with proper pluralization
    #
    # Converts technical unit names to natural language with
    # appropriate singular/plural forms based on the value.
    #
    # ## Examples
    #
    # ```crystal
    # Weight.new(1, Weight::Unit::Kilogram).humanize   # => "1 kilogram"
    # Weight.new(2, Weight::Unit::Kilogram).humanize   # => "2 kilograms"
    # Weight.new(0, Weight::Unit::Kilogram).humanize   # => "0 kilograms"
    # Weight.new(-1, Weight::Unit::Kilogram).humanize  # => "-1 kilogram"
    # Weight.new(1.5, Weight::Unit::Kilogram).humanize # => "1.5 kilograms"
    # ```
    def humanize : String
      value_str = format_value_for_humanization
      unit_name = format_unit_name_for_humanization
      
      if should_pluralize?
        unit_display = get_plural_unit_name(unit_name)
      else
        unit_display = unit_name
      end
      
      "#{value_str} #{unit_display}"
    end
    
    private def format_value(precision : Int32) : String
      # Clamp precision to reasonable bounds
      precision = precision.clamp(0, 10)
      
      # Always format with the specified precision
      if precision == 0
        @value.round(precision).to_i.to_s
      else
        # Convert to float for formatting, then back to string with precision
        sprintf("%.#{precision}f", @value.to_f)
      end
    end
    
    private def format_unit(format : Symbol) : String
      case format
      when :short
        # Use the symbol method if available, otherwise fall back to enum name
        if responds_to?(:symbol)
          symbol
        else
          @unit.to_s.downcase
        end
      when :long
        # Convert enum name to readable format (e.g., Kilogram -> kilogram)
        @unit.to_s.underscore.gsub('_', ' ')
      else
        # Default to enum string representation
        @unit.to_s
      end
    end
    
    private def format_value_for_humanization : String
      # For humanization, show decimals only when necessary
      if @value == @value.to_i
        @value.to_i.to_s
      else
        # Remove trailing zeros for cleaner display
        value_str = @value.to_s
        # Remove trailing zeros after decimal point
        if value_str.includes?('.')
          value_str = value_str.rstrip('0').rstrip('.')
        end
        value_str
      end
    end
    
    private def format_unit_name_for_humanization : String
      # Convert enum name to human-readable lowercase format
      @unit.to_s.underscore.gsub('_', ' ')
    end
    
    private def get_plural_unit_name(unit_name : String) : String
      # Handle special pluralization cases
      case unit_name
      when "inch"
        "inches"
      when "foot"
        "feet"
      else
        "#{unit_name}s"
      end
    end
    
    private def should_pluralize? : Bool
      # Pluralize unless the absolute value is exactly 1
      @value.abs != BigDecimal.new("1")
    end
  end
end