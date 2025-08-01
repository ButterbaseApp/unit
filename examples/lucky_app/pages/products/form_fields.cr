# Shared form fields for product forms
module Products::FormFields
  # Render all product form fields
  def render_product_fields(op : SaveProduct)
    render_basic_fields(op)
    render_measurement_fields(op)
    render_inventory_fields(op)
  end

  private def render_basic_fields(op : SaveProduct)
    div class: "row mb-3" do
      div class: "col-md-6" do
        label_for op.name
        text_input op.name, class: "form-control", required: true
        error_for op.name
      end

      div class: "col-md-6" do
        label_for op.sku, "SKU"
        text_input op.sku, class: "form-control", required: true,
          placeholder: "ABC-123", pattern: "[A-Z0-9\\-]{6,20}"
        error_for op.sku
        small class: "form-text text-muted" do
          text "6-20 characters, uppercase letters, numbers, and hyphens"
        end
      end
    end

    div class: "mb-3" do
      label_for op.description
      textarea op.description, class: "form-control", rows: 3
      error_for op.description
    end
  end

  private def render_measurement_fields(op : SaveProduct)
    h4 "Measurements", class: "mt-4 mb-3"

    # Weight input with unit selector
    div class: "row mb-3" do
      div class: "col-md-6" do
        label_for op.weight, "Weight"
        div class: "input-group" do
          # If we have a parsed weight, show it
          if weight = op.weight.value
            number_input name: "product:weight_value",
              value: weight.value.to_s,
              class: "form-control",
              step: "0.001",
              min: "0.001"
            select_input name: "product:weight_unit", class: "form-select" do
              weight_unit_options(weight.unit)
            end
          else
            # Show string input for parsing
            text_input op.weight_string, class: "form-control",
              placeholder: "e.g., 2.5 kg or 5 pounds"
          end
        end
        error_for op.weight
        small class: "form-text text-muted" do
          text "Enter weight with unit (e.g., '2.5 kg' or '5 lb')"
        end
      end
    end

    # Dimensions inputs
    div class: "row mb-3" do
      div class: "col-md-4" do
        label "Length"
        measurement_input(op, :length, op.length_string)
      end

      div class: "col-md-4" do
        label "Width"
        measurement_input(op, :width, op.width_string)
      end

      div class: "col-md-4" do
        label "Height"
        measurement_input(op, :height, op.height_string)
      end
    end

    # Show calculated values if available
    if saved_product = op.record
      div class: "alert alert-info" do
        h6 "Calculated Values"
        ul class: "mb-0" do
          if volume = saved_product.volume
            li "Volume: #{volume.humanize}"
          end
          li "Shipping Weight: #{saved_product.shipping_weight.humanize}"
          li "Dimensional Weight: #{saved_product.dimensional_weight.humanize}"
          if saved_product.oversized_for_shipping?
            li do
              span class: "text-danger" do
                text "⚠️ Oversized for standard shipping"
              end
            end
          end
        end
      end
    end
  end

  private def measurement_input(op : SaveProduct, field : Symbol, string_attr)
    div class: "input-group" do
      text_input string_attr, class: "form-control",
        placeholder: "e.g., 30 cm"
    end

    case field
    when :length then error_for op.length
    when :width  then error_for op.width
    when :height then error_for op.height
    end

    small class: "form-text text-muted" do
      text "With unit (cm, in, m, ft)"
    end
  end

  private def render_inventory_fields(op : SaveProduct)
    h4 "Pricing & Inventory", class: "mt-4 mb-3"

    div class: "row mb-3" do
      div class: "col-md-6" do
        label_for op.price_cents, "Price"
        div class: "input-group" do
          span class: "input-group-text" do
            text "$"
          end
          # Convert cents to dollars for display
          price_dollars = op.price_cents.value.try { |cents| cents / 100.0 } || 0.0
          number_input name: "product:price_dollars",
            value: price_dollars,
            class: "form-control",
            step: "0.01",
            min: "0"
        end
        error_for op.price_cents
      end

      div class: "col-md-6" do
        label_for op.stock_quantity, "Stock Quantity"
        number_input op.stock_quantity, class: "form-control",
          min: "0", value: op.stock_quantity.value || 0
        error_for op.stock_quantity
      end
    end
  end

  private def weight_unit_options(selected : Unit::Weight::Unit? = nil)
    units = [
      {Unit::Weight::Unit::Kilogram, "Kilograms (kg)"},
      {Unit::Weight::Unit::Gram, "Grams (g)"},
      {Unit::Weight::Unit::Pound, "Pounds (lb)"},
      {Unit::Weight::Unit::Ounce, "Ounces (oz)"},
    ]

    units.each do |unit, label|
      if selected == unit
        option label, value: unit.to_s.downcase, selected: "selected"
      else
        option label, value: unit.to_s.downcase
      end
    end
  end

  # JavaScript for enhanced form behavior
  def measurement_form_scripts
    script do
      raw <<-JS
        // Toggle between string and structured input
        document.querySelectorAll('.measurement-toggle').forEach(toggle => {
          toggle.addEventListener('click', (e) => {
            e.preventDefault();
            const stringInput = toggle.closest('.form-group').querySelector('.string-input');
            const structuredInput = toggle.closest('.form-group').querySelector('.structured-input');

            if (stringInput.style.display === 'none') {
              stringInput.style.display = 'block';
              structuredInput.style.display = 'none';
            } else {
              stringInput.style.display = 'none';
              structuredInput.style.display = 'block';
            }
          });
        });

        // Convert price dollars to cents
        const priceInput = document.querySelector('input[name="product:price_dollars"]');
        if (priceInput) {
          const form = priceInput.closest('form');
          form.addEventListener('submit', (e) => {
            const cents = Math.round(parseFloat(priceInput.value) * 100);
            const hiddenInput = document.createElement('input');
            hiddenInput.type = 'hidden';
            hiddenInput.name = 'product:price_cents';
            hiddenInput.value = cents;
            form.appendChild(hiddenInput);
          });
        }
      JS
    end
  end
end
