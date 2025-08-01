require "json"
require "yaml"

module Unit
  module EnumConverter(T)
    def self.from_json(parser : JSON::PullParser) : T
      value = parser.read_string
      parse_enum(value, parser)
    end

    def self.to_json(value : T, json : JSON::Builder)
      json.string(value.to_s)
    end

    def self.from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node) : T
      unless node.is_a?(YAML::Nodes::Scalar)
        node.raise "Expected scalar, not #{node.class}"
      end
      
      parse_enum(node.value, node)
    end

    def self.to_yaml(value : T, yaml : YAML::Nodes::Builder)
      yaml.scalar(value.to_s)
    end

    private def self.parse_enum(value : String, error_context)
      # Try exact match first
      T.parse?(value) || begin
        # Try case-insensitive match
        normalized = value.downcase
        T.each do |enum_value|
          return enum_value if enum_value.to_s.downcase == normalized
        end
        
        # If no match found, raise an error
        valid_values = T.values.map(&.to_s).join(", ")
        error_context.raise "Invalid #{T} value: '#{value}'. Valid values are: #{valid_values}"
      end
    end
  end
end