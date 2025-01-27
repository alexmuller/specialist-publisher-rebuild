class Facet
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :key
  attribute :name
  attribute :short_name
  attribute :type
  attribute :preposition
  attribute :display_as_result_metadata, :boolean
  attribute :filterable, :boolean
  attribute :allowed_values
  attribute :specialist_publisher_properties

  def to_finder_schema_attributes
    {
      allowed_values:,
      display_as_result_metadata:,
      filterable:,
      key:,
      name:,
      preposition:,
      specialist_publisher_properties:,
      short_name:,
      type:,
    }.compact
  end

  class << self
    def from_finder_admin_form_params(params)
      facet = new
      facet.key = facet_key(params["key"], params["name"])
      facet.name = params["name"]
      facet.short_name = nil_if_blank(params["short_name"])
      facet.type = facet_type(params["type"])
      facet.preposition = nil_if_blank(params["preposition"])
      facet.display_as_result_metadata = params["display_as_result_metadata"]
      facet.filterable = params["filterable"]
      facet.allowed_values = facet_allowed_values(params["allowed_values"], params["type"])
      facet.specialist_publisher_properties = facet_specialist_publisher_properties(params["type"], params["validations"])
      facet
    end

  private

    def facet_key(key, name)
      key.presence || name&.gsub(" ", "")&.underscore
    end

    def nil_if_blank(str)
      str.presence
    end

    def facet_type(type)
      facet_types_that_allow_enum_values.include?(type) ? "text" : type
    end

    def facet_allowed_values(values, type)
      return nil if values.nil? || facet_types_that_allow_enum_values.exclude?(type)

      values.split("\n").map do |str|
        label = str.match(/^(.+){/)
        label = label.nil? ? str.strip : label[1].strip
        value = str.match(/{(.+)}/)
        value = value.nil? ? str.strip.downcase.gsub(/[^\w\d\s]/, "").gsub(/\s/u, "-") : value[1].strip
        { label:, value: }
      end
    end

    def facet_specialist_publisher_properties(type, validations)
      properties = facet_specialist_publisher_properties_select(type).merge(facet_specialist_publisher_properties_validations(validations))

      properties.presence
    end

    def facet_specialist_publisher_properties_select(type)
      case type
      when "enum_text_multiple"
        { select: "multiple" }
      when "enum_text_single"
        { select: "one" }
      else
        {}
      end
    end

    def facet_specialist_publisher_properties_validations(validations)
      return {} unless validations

      rules = {}
      validations.each do |key|
        rules[key.to_sym] = {}
      end

      { validations: rules }
    end

    def facet_types_that_allow_enum_values
      %w[enum_text_multiple enum_text_single]
    end
  end
end
