require "big"
require "json"
require "yaml"

module Unit
  module BigDecimalConverter
    def self.from_json(parser : JSON::PullParser) : BigDecimal
      BigDecimal.new(parser.read_string)
    rescue ex : ArgumentError
      parser.raise "Invalid decimal value: #{ex.message}"
    end

    def self.to_json(value : BigDecimal, json : JSON::Builder)
      json.string(value.to_s)
    end

    def self.from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node) : BigDecimal
      unless node.is_a?(YAML::Nodes::Scalar)
        node.raise "Expected scalar, not #{node.class}"
      end
      
      BigDecimal.new(node.value)
    rescue ex : ArgumentError
      node.raise "Invalid decimal value: #{ex.message}"
    end

    def self.to_yaml(value : BigDecimal, yaml : YAML::Nodes::Builder)
      yaml.scalar(value.to_s)
    end
  end
end