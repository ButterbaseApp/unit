# Example Lucky page showing products with measurements
class Products::IndexPage < MainLayout
  needs products : ProductQuery
  needs weight_unit : String = "kilogram"
  needs dimension_unit : String = "centimeter"

  def content
    h1 "Products Inventory"

    unit_selector
    product_filters
    product_table
  end

  private def unit_selector
    div class: "unit-selector mb-4" do
      form action: Products::Index.path, method: "GET" do
        label "Display units:" do
          text " Weight: "
          select_input name: "weight_unit", value: weight_unit do
            options_for_select([
              {"Kilograms", "kilogram"},
              {"Pounds", "pound"},
              {"Grams", "gram"},
              {"Ounces", "ounce"},
            ], weight_unit)
          end

          text " Dimensions: "
          select_input name: "dimension_unit", value: dimension_unit do
            options_for_select([
              {"Centimeters", "centimeter"},
              {"Inches", "inch"},
              {"Meters", "meter"},
              {"Feet", "foot"},
            ], dimension_unit)
          end

          submit "Update", class: "btn btn-sm btn-primary"
        end
      end
    end
  end

  private def product_filters
    div class: "filters mb-4" do
      h3 "Quick Filters"

      div class: "btn-group" do
        link "All", to: Products::Index.path, class: "btn btn-outline-primary"
        link "Lightweight (< 1kg)",
          to: Products::Index.with(filter: "lightweight"),
          class: "btn btn-outline-primary"
        link "Standard Shipping",
          to: Products::Index.with(filter: "standard"),
          class: "btn btn-outline-primary"
        link "Oversized",
          to: Products::Index.with(filter: "oversized"),
          class: "btn btn-outline-primary"
      end
    end
  end

  private def product_table
    div class: "table-responsive" do
      table class: "table table-striped" do
        thead do
          tr do
            th "SKU"
            th "Name"
            th "Weight"
            th "Dimensions"
            th "Volume"
            th "Shipping Weight"
            th "Price"
            th "Stock"
            th "Actions"
          end
        end

        tbody do
          products.each do |product|
            product_row(product)
          end
        end
      end
    end

    if products.none?
      div class: "alert alert-info" do
        text "No products found."
      end
    end
  end

  private def product_row(product : Product)
    tr class: row_class(product) do
      td product.sku
      td product.name
      td format_weight(product.weight)
      td product.dimensions_string(dimension_unit.to_sym)
      td format_volume(product.volume)
      td do
        format_weight(product.shipping_weight)
        if product.shipping_weight > product.weight
          span class: "badge badge-warning ms-2" do
            text "DIM"
          end
        end
      end
      td "$#{product.price}"
      td do
        if product.in_stock?
          span class: "badge badge-success" do
            text product.stock_quantity.to_s
          end
        else
          span class: "badge badge-danger" do
            text "Out of Stock"
          end
        end
      end
      td do
        link "Edit", to: Products::Edit.with(product.id),
          class: "btn btn-sm btn-primary"
      end
    end
  end

  private def row_class(product : Product) : String
    classes = [] of String
    classes << "table-warning" if product.oversized_for_shipping?
    classes << "table-secondary" unless product.in_stock?
    classes.join(" ")
  end

  private def format_weight(weight : Unit::Weight) : String
    weight.to(weight_unit.to_sym).format(precision: 2)
  end

  private def format_volume(volume : Unit::Volume?) : String
    return "—" unless volume

    if volume.value > BigDecimal.new("1000")
      # Show in cubic meters for large volumes
      m3 = volume.value / BigDecimal.new("1000")
      "#{m3.round(3)} m³"
    else
      "#{volume.format(precision: 1)}"
    end
  end
end
