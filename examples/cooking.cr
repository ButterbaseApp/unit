require "../src/unit"

# Cooking and Recipe Examples
# Demonstrates practical use of the Unit library for cooking applications

puts "=== Basic Recipe Conversions ==="

# Common cooking conversions
cup_flour = Unit::Volume.new(1, :cup)
puts "1 cup = #{cup_flour.to(:tablespoon)} tablespoons"
puts "1 cup = #{cup_flour.to(:teaspoon)} teaspoons"
puts "1 cup = #{cup_flour.to(:fluid_ounce)} fluid ounces"
puts "1 cup = #{cup_flour.to(:milliliter).format(precision: 0)} milliliters"

puts "\n=== Recipe Scaling ==="

# Original recipe (serves 4)
class Recipe
  property flour : Unit::Volume
  property sugar : Unit::Volume
  property milk : Unit::Volume
  property butter : Unit::Weight
  
  def initialize(@flour, @sugar, @milk, @butter)
  end
  
  def scale(factor : Number)
    Recipe.new(
      Unit::Volume.new(@flour.value * factor, @flour.unit),
      Unit::Volume.new(@sugar.value * factor, @sugar.unit),
      Unit::Volume.new(@milk.value * factor, @milk.unit),
      Unit::Weight.new(@butter.value * factor, @butter.unit)
    )
  end
  
  def to_s(io)
    io << "Recipe:\n"
    io << "  Flour: #{@flour.humanize}\n"
    io << "  Sugar: #{@sugar.humanize}\n"
    io << "  Milk: #{@milk.humanize}\n"
    io << "  Butter: #{@butter.humanize}"
  end
end

original = Recipe.new(
  flour: Unit::Volume.new(2, :cup),
  sugar: Unit::Volume.new(0.5, :cup),
  milk: Unit::Volume.new(1.25, :cup),
  butter: Unit::Weight.new(8, :ounce)  # 2 sticks
)

puts "Original recipe (serves 4):"
puts original

# Scale for 6 people
scaled = original.scale(1.5)
puts "\nScaled recipe (serves 6):"
puts scaled

# Scale down for 2 people
half_recipe = original.scale(0.5)
puts "\nHalf recipe (serves 2):"
puts half_recipe

puts "\n=== International Recipe Conversion ==="

# Convert an American recipe to metric
american_recipe = {
  flour: Unit::Volume.new(3, :cup),
  sugar: Unit::Volume.new(1, :cup),
  milk: Unit::Volume.new(2, :cup),
  vanilla: Unit::Volume.new(2, :teaspoon),
  salt: Unit::Volume.new(0.5, :teaspoon)
}

puts "American Recipe:"
american_recipe.each do |ingredient, amount|
  puts "  #{ingredient}: #{amount}"
end

puts "\nMetric Conversion:"
american_recipe.each do |ingredient, amount|
  metric = amount.to(:milliliter)
  # Round to practical measurements
  rounded = case metric.value
            when .>(1000)
              Unit::Volume.new((metric.value / 1000).round(2), :liter)
            else
              Unit::Volume.new(metric.value.round(-1), :milliliter)  # Round to nearest 10
            end
  puts "  #{ingredient}: #{rounded.humanize}"
end

puts "\n=== Weight vs Volume for Ingredients ==="

# Flour weight varies by measuring method
flour_cup = Unit::Volume.new(1, :cup)
flour_weight_sifted = Unit::Weight.new(120, :gram)
flour_weight_scooped = Unit::Weight.new(140, :gram)
flour_weight_packed = Unit::Weight.new(160, :gram)

puts "1 cup of flour by weight:"
puts "  Sifted: #{flour_weight_sifted}"
puts "  Scooped: #{flour_weight_scooped}"
puts "  Packed: #{flour_weight_packed}"
puts "\nThis is why baking by weight is more accurate!"

puts "\n=== Temperature Monitoring (Simulated) ==="

# While we don't have a Temperature measurement, we can simulate
class Temperature
  getter celsius : BigDecimal
  
  def initialize(@celsius : Number)
    @celsius = BigDecimal.new(@celsius.to_s)
  end
  
  def fahrenheit
    (@celsius * 9 / 5) + 32
  end
  
  def to_s(io)
    io << "#{@celsius}°C (#{fahrenheit.round(0)}°F)"
  end
end

oven_temp = Temperature.new(180)
puts "Oven temperature: #{oven_temp}"

water_boiling = Temperature.new(100)
puts "Water boiling: #{water_boiling}"

candy_soft_ball = Temperature.new(115)
puts "Soft ball stage: #{candy_soft_ball}"

puts "\n=== Ingredient Substitutions ==="

# Butter to oil conversion
butter = Unit::Weight.new(100, :gram)
# Rule of thumb: 100g butter ≈ 80ml oil
oil_ml = butter.value * BigDecimal.new("0.8")
oil = Unit::Volume.new(oil_ml, :milliliter)

puts "Substitution:"
puts "  #{butter} butter ≈ #{oil} oil"

# Honey to sugar conversion
sugar = Unit::Volume.new(1, :cup)
# Rule: 3/4 cup honey per 1 cup sugar
honey = Unit::Volume.new(sugar.value * BigDecimal.new("0.75"), :cup)
puts "  #{sugar} sugar ≈ #{honey} honey (reduce liquid by 1/4 cup)"

puts "\n=== Yield Calculations ==="

# Cookie recipe yield
class CookieRecipe
  property dough_weight : Unit::Weight
  property cookies_per_batch : Int32
  property cookie_weight : Unit::Weight
  
  def initialize(@dough_weight, @cookies_per_batch, @cookie_weight)
  end
  
  def total_cookies
    (@dough_weight.value / @cookie_weight.value).to_i
  end
  
  def batches_needed
    (total_cookies.to_f / @cookies_per_batch).ceil
  end
end

recipe = CookieRecipe.new(
  dough_weight: Unit::Weight.new(1.5, :kilogram),
  cookies_per_batch: 12,
  cookie_weight: Unit::Weight.new(30, :gram)
)

puts "Cookie Production:"
puts "  Total dough: #{recipe.dough_weight}"
puts "  Weight per cookie: #{recipe.cookie_weight}"
puts "  Total cookies: #{recipe.total_cookies}"
puts "  Batches needed: #{recipe.batches_needed}"

puts "\n=== Shopping List Aggregation ==="

# Combine ingredients from multiple recipes
shopping_list = Hash(String, Unit::Volume | Unit::Weight).new

# Recipe 1
shopping_list["flour"] = Unit::Volume.new(3, :cup)
shopping_list["sugar"] = Unit::Volume.new(2, :cup)
shopping_list["butter"] = Unit::Weight.new(1, :pound)

# Recipe 2 (adding to existing)
flour2 = Unit::Volume.new(2.5, :cup)
sugar2 = Unit::Volume.new(1.5, :cup)
butter2 = Unit::Weight.new(8, :ounce)

# Add to shopping list
if current = shopping_list["flour"]?
  shopping_list["flour"] = Unit::Volume.new(
    current.as(Unit::Volume).value + flour2.value, 
    :cup
  )
end

if current = shopping_list["sugar"]?
  shopping_list["sugar"] = Unit::Volume.new(
    current.as(Unit::Volume).value + sugar2.value,
    :cup
  )
end

if current = shopping_list["butter"]?
  # Convert to same unit first
  current_butter = current.as(Unit::Weight)
  butter2_pounds = butter2.to(:pound)
  shopping_list["butter"] = Unit::Weight.new(
    current_butter.value + butter2_pounds.value,
    :pound
  )
end

puts "Shopping List (combined from 2 recipes):"
shopping_list.each do |item, amount|
  puts "  #{item}: #{amount.humanize}"
end

puts "\n=== Nutrition Calculations ==="

# Calculate calories from macros (simplified)
class NutritionCalc
  CALORIES_PER_GRAM = {
    carbs: BigDecimal.new("4"),
    protein: BigDecimal.new("4"),
    fat: BigDecimal.new("9")
  }
  
  def self.calculate_calories(carbs : Unit::Weight, protein : Unit::Weight, fat : Unit::Weight)
    carb_cal = carbs.to(:gram).value * CALORIES_PER_GRAM[:carbs]
    protein_cal = protein.to(:gram).value * CALORIES_PER_GRAM[:protein]
    fat_cal = fat.to(:gram).value * CALORIES_PER_GRAM[:fat]
    
    {
      carbs: carb_cal,
      protein: protein_cal,
      fat: fat_cal,
      total: carb_cal + protein_cal + fat_cal
    }
  end
end

# Example food item
food_carbs = Unit::Weight.new(30, :gram)
food_protein = Unit::Weight.new(20, :gram)
food_fat = Unit::Weight.new(10, :gram)

calories = NutritionCalc.calculate_calories(food_carbs, food_protein, food_fat)
puts "Nutritional Information:"
puts "  Carbs: #{food_carbs} = #{calories[:carbs].round(0)} cal"
puts "  Protein: #{food_protein} = #{calories[:protein].round(0)} cal"
puts "  Fat: #{food_fat} = #{calories[:fat].round(0)} cal"
puts "  Total: #{calories[:total].round(0)} calories"

puts "\n=== Summary ==="
puts "The Unit library in cooking applications provides:"
puts "- Accurate recipe scaling"
puts "- Easy metric/imperial conversions"
puts "- Precise measurements for baking"
puts "- Shopping list aggregation"
puts "- Nutritional calculations"