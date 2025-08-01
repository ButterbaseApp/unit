require "../src/unit"

# Demonstrate the string parsing capabilities
puts "=== Unit String Parsing Demo ==="
puts

# Weight parsing examples
puts "Weight Parsing:"
weight1 = Unit::Parser.parse(Unit::Weight, "10.5 kg")
puts "  '10.5 kg' -> #{weight1.inspect}"

weight2 = Unit::Parser.parse(Unit::Weight, "1/2 pound")
puts "  '1/2 pound' -> #{weight2.inspect}"

weight3 = Unit::Parser.parse(Unit::Weight, "-3 g")
puts "  '-3 g' -> #{weight3.inspect}"

weight4 = Unit::Parser.parse(Unit::Weight, "2oz")
puts "  '2oz' -> #{weight4.inspect}"

weight5 = Unit::Parser.parse(Unit::Weight, "  5.5  POUNDS  ")
puts "  '  5.5  POUNDS  ' -> #{weight5.inspect}"

puts

# Length parsing examples  
puts "Length Parsing:"
length1 = Unit::Parser.parse(Unit::Length, "10.5 m")
puts "  '10.5 m' -> #{length1.inspect}"

length2 = Unit::Parser.parse(Unit::Length, "1/2 foot")
puts "  '1/2 foot' -> #{length2.inspect}"

length3 = Unit::Parser.parse(Unit::Length, "-3 cm")
puts "  '-3 cm' -> #{length3.inspect}"

length4 = Unit::Parser.parse(Unit::Length, "12inches")
puts "  '12inches' -> #{length4.inspect}"

length5 = Unit::Parser.parse(Unit::Length, "  5.5  FEET  ")
puts "  '  5.5  FEET  ' -> #{length5.inspect}"

puts

# Demonstrate unit aliases and plural forms
puts "Unit Aliases & Plurals:"
puts "  'kg' -> #{Unit::Parser.parse(Unit::Weight, "1 kg").unit}"
puts "  'pounds' -> #{Unit::Parser.parse(Unit::Weight, "1 pounds").unit}"
puts "  'cm' -> #{Unit::Parser.parse(Unit::Length, "1 cm").unit}"
puts "  'feet' -> #{Unit::Parser.parse(Unit::Length, "1 feet").unit}"
puts "  'inches' -> #{Unit::Parser.parse(Unit::Length, "1 inches").unit}"

puts

# Demonstrate error handling
puts "Error Handling:"
begin
  Unit::Parser.parse(Unit::Weight, "invalid")
rescue e : ArgumentError
  puts "  'invalid' -> #{e.message}"
end

begin
  Unit::Parser.parse(Unit::Weight, "10 xyz")
rescue e : ArgumentError
  puts "  '10 xyz' -> #{e.message}"
end

begin
  Unit::Parser.parse(Unit::Weight, "1/0 kg")
rescue e : ArgumentError
  puts "  '1/0 kg' -> #{e.message}"
end