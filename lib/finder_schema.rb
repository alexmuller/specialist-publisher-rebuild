class FinderSchema
  attr_reader :base_path, :organisations, :document_type_filter

  def initialize(schema_type)
    @schema ||= load_schema_for(schema_type)
    @base_path = schema.fetch("base_path")
    @organisations = schema.fetch("organisations", [])
    @document_type_filter = schema.fetch("filter", {}).fetch("document_type")
  end

  def facets
    schema.fetch("facets", []).map do |facet|
      facet.fetch("key").to_sym
    end
  end

  def options_for(facet_name)
    allowed_values_as_option_tuples(allowed_values_for(facet_name))
  end

  def humanized_facet_value(facet_key, value)
    type = facet_data_for(facet_key).fetch("type", nil)
    case
    when type == "text" && allowed_values_for(facet_key).empty?
      value
    when type == "text"
      Array(value).map do |v|
        value_label_mapping_for(facet_key, v).fetch("label") { value }
      end
    else
      value_label_mapping_for(facet_key, value).fetch("label") { value }
    end
  end

  def humanized_facet_name(key)
    facet_data_for(key).fetch("name") { key }
  end

private

  attr_reader :schema

  def load_schema_for(type)
    YAML.load_file(Rails.root.join("lib/documents/schemas/#{type}.yml"))
  end

  def facet_data_for(facet_name)
    schema.fetch("facets", []).find do |facet_record|
      facet_record.fetch("key") == facet_name.to_s
    end || {}
  end

  def allowed_values_for(facet_name)
    facet_data_for(facet_name).fetch("allowed_values", [])
  end

  def allowed_values_as_option_tuples(allowed_values)
    allowed_values.map do |value|
      [
        value.fetch("label", ""),
        value.fetch("value", "")
      ]
    end
  end

  def value_label_mapping_for(facet_key, value)
    allowed_values_for(facet_key).find do |allowed_value|
      allowed_value.fetch("value") == value.to_s
    end || {}
  end
end
