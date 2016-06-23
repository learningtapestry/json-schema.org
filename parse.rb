require 'json'
require 'faraday'

class Parser
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def schema
    {
      "$schema": "http://json-schema.org/draft-04/schema#",
      "description": "Schema.org #{type}",
      "@type": type,
      "type": "object",
      "definitions": parsed_definitions,
      "allOf": definitions.keys.map { |name| "#definitions/#{name}" }
    }
  end

  def data
    @data ||= JSON.parse source
  end

  def type
    data['type']
  end

  def source
    path = File.expand_path("./sources/#{name}.json")
    File.read path
  end

  def definitions
    @definitions ||= begin
      defs = data['bases'] || {}
      defs[type] = data['properties'] if data['properties']
      defs
    end
  end

  def parsed_definitions
    @parsed_definitions ||= begin
      defs = {}
      definitions.each do |name, props|
        defs[name] = {
          '@type': name,
          type: 'object',
          properties: parsed_properties(props)
        }
      end
      defs
    end
  end

  def parsed_properties(properties)
    props_arr = properties.map do |prop|
      attrs = {}
      attrs['description'] = prop['description']

      case prop['type']
      when 'Text'
        attrs['type'] = 'string'
      when 'URL'
        attrs['type'] = 'string'
        attrs['format'] = 'uri'
      when 'Date'
        attrs['type'] = 'string'
        attrs['format'] = 'date'
      when 'Number'
        attrs['type'] = 'number'
      when 'Boolean'
        attrs['type'] == 'boolean'
      else
        if prop['type'].is_a? Array
          attrs['anyOf'] = prop['type'].map {|t| {'$ref': "#{t}.json"} }
        else
          attrs['$ref'] = "#{prop['type']}.json"
        end
      end

      [prop['name'], attrs]
    end
    Hash[ *props_arr.flatten ]
  end
end


def parse_all
  folder = File.expand_path './sources'
  Dir.foreach(folder) do |filename|
    next if filename.start_with?('.')
    name = filename.gsub '.json', ''
    parser =  Parser.new(name)

    output_file = "./schemas/#{parser.type}.json"
    File.open output_file, 'w' do |f|
      f.write JSON.pretty_unparse(parser.schema)
      puts ">> #{output_file}"
    end
  end
end

if __FILE__ == $0
  parse_all
end
