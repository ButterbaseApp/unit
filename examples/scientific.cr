require "../src/unit"
require "big"

# Scientific Calculations with High Precision
# Demonstrates the Unit library's capabilities for scientific and engineering calculations

puts "=== Physical Constants ==="

# Speed of light in vacuum
c_meters = Unit::Length.new(BigDecimal.new("299792458"), :meter)
time_seconds = BigDecimal.new("1")
puts "Speed of light: #{c_meters} per #{time_seconds} second"
puts "Speed of light: #{c_meters.to(:kilometer)} per #{time_seconds} second"

# Planck's constant (using mass-energy equivalence)
# h = 6.62607015 × 10^-34 kg⋅m²/s
planck_mass = Unit::Weight.new(BigDecimal.new("6.62607015e-34"), :kilogram)
puts "\nPlanck constant (mass component): #{planck_mass} (×m²/s)"

puts "\n=== Precision in Conversions ==="

# Demonstrate high-precision conversions
precise_mass = Unit::Weight.new(BigDecimal.new("1.00000000000000"), :kilogram)
puts "Original mass: #{precise_mass.format(precision: 14)}"

# Convert through multiple units and back
converted = precise_mass
  .to(:gram)
  .to(:milligram)
  .to(:pound)
  .to(:ounce)
  .to(:gram)
  .to(:kilogram)

puts "After conversions: #{converted.format(precision: 14)}"
puts "Difference: #{(converted.value - precise_mass.value).abs}"

puts "\n=== Astronomical Distances ==="

# Earth-Sun distance (1 AU)
au_meters = BigDecimal.new("149597870700") # meters
astronomical_unit = Unit::Length.new(au_meters, :meter)

puts "1 AU = #{astronomical_unit} meters"
puts "1 AU = #{astronomical_unit.to(:kilometer)} kilometers"
puts "1 AU = #{astronomical_unit.to(:mile)} miles"

# Light travel time to the Sun
light_speed_ms = BigDecimal.new("299792458") # m/s
time_to_sun = au_meters / light_speed_ms
puts "Light travel time to Sun: #{time_to_sun.round(2)} seconds"
puts "Light travel time to Sun: #{(time_to_sun / 60).round(2)} minutes"

puts "\n=== Particle Physics ==="

# Electron mass
electron_mass = Unit::Weight.new(BigDecimal.new("9.1093837015e-31"), :kilogram)
puts "Electron mass: #{electron_mass} kg"
puts "Electron mass: #{electron_mass.to(:gram)} g"

# Proton mass
proton_mass = Unit::Weight.new(BigDecimal.new("1.67262192369e-27"), :kilogram)
puts "Proton mass: #{proton_mass} kg"

# Mass ratio
mass_ratio = proton_mass.value / electron_mass.value
puts "Proton/electron mass ratio: #{mass_ratio.round(2)}"

puts "\n=== Engineering Calculations ==="

# Structural beam calculations
beam_length = Unit::Length.new(BigDecimal.new("6.5"), :meter)
load = Unit::Weight.new(BigDecimal.new("5000"), :kilogram)

puts "Beam specifications:"
puts "  Length: #{beam_length}"
puts "  Load: #{load}"
puts "  Length (ft): #{beam_length.to(:foot).format(precision: 2)}"
puts "  Load (lb): #{load.to(:pound).format(precision: 0)}"

# Pressure calculation (force/area)
# Note: This is a simplified example - a real Pressure measurement would be ideal
force_newtons = load.value * BigDecimal.new("9.80665") # kg to N
area_m2 = BigDecimal.new("0.01")                       # 100 cm²
pressure_pa = force_newtons / area_m2
puts "\nPressure on 100 cm² area: #{pressure_pa.round(2)} Pa"
puts "Pressure: #{(pressure_pa / 1000).round(2)} kPa"

puts "\n=== Chemical Calculations ==="

# Molar mass of water (H2O)
# H: 1.008 g/mol × 2 = 2.016 g/mol
# O: 15.999 g/mol × 1 = 15.999 g/mol
# Total: 18.015 g/mol

molar_mass_water = Unit::Weight.new(BigDecimal.new("18.015"), :gram)
puts "Molar mass of H₂O: #{molar_mass_water}/mol"

# Calculate mass of 2.5 moles
moles = BigDecimal.new("2.5")
mass_of_sample = Unit::Weight.new(molar_mass_water.value * moles, :gram)
puts "Mass of #{moles} moles of H₂O: #{mass_of_sample}"
puts "Mass in kg: #{mass_of_sample.to(:kilogram).format(precision: 4)}"

puts "\n=== Relativistic Calculations ==="

# Relativistic mass increase
rest_mass = Unit::Weight.new(BigDecimal.new("1"), :kilogram)
velocity_fraction = BigDecimal.new("0.9") # 0.9c

# Lorentz factor: γ = 1/√(1 - v²/c²)
v_squared = velocity_fraction ** 2
lorentz_factor = BigDecimal.new("1") / (BigDecimal.new("1") - v_squared).sqrt(50)
relativistic_mass = Unit::Weight.new(rest_mass.value * lorentz_factor, :kilogram)

puts "Rest mass: #{rest_mass}"
puts "Velocity: #{velocity_fraction}c"
puts "Lorentz factor: #{lorentz_factor.round(4)}"
puts "Relativistic mass: #{relativistic_mass.format(precision: 4)}"

puts "\n=== Precision Benchmark ==="

# Compare BigDecimal precision with Float
puts "\nUsing BigDecimal (Unit library):"
precise_value = Unit::Length.new(BigDecimal.new("1") / BigDecimal.new("3"), :meter)
puts "1/3 meter = #{precise_value.value} m"
puts "×3 = #{(precise_value.value * 3)} m"

puts "\nUsing Float64 directly:"
float_value = 1.0 / 3.0
puts "1/3 = #{float_value}"
puts "×3 = #{float_value * 3}"
puts "Error: #{(float_value * 3) - 1.0}"

puts "\n=== Scientific Notation ==="

# Very large numbers
avogadro = BigDecimal.new("6.02214076e23")
puts "\nAvogadro's number: #{avogadro}"

# Very small numbers
planck_length = Unit::Length.new(BigDecimal.new("1.616255e-35"), :meter)
puts "Planck length: #{planck_length} m"
puts "In scientific notation: #{planck_length.value.to_s("E")}"

# Scale comparison
scale_ratio = astronomical_unit.value / planck_length.value
puts "\nScale from Planck length to 1 AU: #{scale_ratio.to_s("E")}"

puts "\n=== Summary ==="
puts "The Unit library with BigDecimal provides:"
puts "- Arbitrary precision for scientific calculations"
puts "- No floating-point rounding errors"
puts "- Suitable for physics, engineering, and chemistry"
puts "- Maintains precision through complex conversions"
