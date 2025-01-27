require "spec_helper"

RSpec.describe "Sense-checks for every finder schema" do
  Dir["lib/documents/schemas/*.json"].map { |file| JSON.parse(File.read(file)) }.each do |finder_schema|
    it "has 'specialist_publisher_properties' for every facet with 'allowed_values'" do
      facets = finder_schema["facets"]

      facets.each do |facet|
        if facet["allowed_values"]
          expect(facet["specialist_publisher_properties"]).to be_truthy, "In the '#{finder_schema['filter']['format']}' finder, facet '#{facet['key']}' is missing 'specialist_publisher_properties' despite having 'allowed_values'"
        end
      end
    end

    it "has 'specialist_publisher_properties' that are valid" do
      finder_schema["facets"].each do |facet|
        next unless facet["specialist_publisher_properties"]

        valid_keys = %w[select omit_from_finder_content_item validations]
        facet["specialist_publisher_properties"].each_key do |key|
          expect(valid_keys).to include(key), "In the '#{finder_schema['filter']['format']}' finder, facet '#{facet['key']}' has an invalid 'specialist_publisher_properties' key: '#{key}'"
        end
      end
    end

    it "has valid 'validations' configuration" do
      finder_schema["facets"].each do |facet|
        next unless facet["specialist_publisher_properties"] && facet["specialist_publisher_properties"]["validations"]

        valid_validation_keys = %w[required]
        facet["specialist_publisher_properties"]["validations"].each_key do |key|
          expect(valid_validation_keys).to include(key), "In the '#{finder_schema['filter']['format']}' finder, facet '#{facet['key']}' has an invalid 'validations' key: '#{key}'"
        end
      end
    end
  end
end
