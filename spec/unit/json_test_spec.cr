require "../spec_helper"
require "json"

describe "JSON Test" do
  it "tests basic JSON serialization" do
    weight = Unit::Weight.new(100, :gram)
    
    # Test to_json with IO
    io = IO::Memory.new
    weight.to_json(io)
    json_string = io.to_s
    json_string.should_not be_empty
    
    # Test to_json that returns string
    json_string2 = weight.to_json
    json_string2.should eq(json_string)
    
    # Test from_json
    deserialized = Unit::Weight.from_json(json_string)
    deserialized.value.should eq(weight.value)
    deserialized.unit.should eq(weight.unit)
  end
end