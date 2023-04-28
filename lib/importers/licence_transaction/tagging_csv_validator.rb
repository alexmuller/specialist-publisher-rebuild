module Importers
  module LicenceTransaction
    class TaggingCsvValidator
      attr_reader :licences_tagging

      def initialize(licences_tagging)
        @licences_tagging = licences_tagging
      end

      def valid?
        tagging_validation_errors.empty?
      end

      def errors
        return if valid?

        tagging_validation_errors.each { |e| puts "#{e}\n\n" }
        puts unrecognised_tags_instructions
      end

    private

      def tagging_validation_errors
        @tagging_validation_errors ||= licences_tagging.filter_map do |tagging|
          unrecognised_locations = tagging["locations"] - schema_values["licence_transaction_location"]
          unrecognised_industries = tagging["industries"] - schema_values["licence_transaction_industry"]

          next if unrecognised_locations.empty? && unrecognised_industries.empty?

          "Unrecognised tags for #{tagging['base_path']}:\n locations: #{unrecognised_locations},\n industries: #{unrecognised_industries}"
        end
      end

      def schema_values
        @schema_values ||= parsed_licence_schema["facets"].each_with_object({}) do |facet, hash|
          if %w[licence_transaction_industry licence_transaction_location].include?(facet["key"])
            hash[facet["key"]] = facet["allowed_values"].map { |v| v["value"] }
          end
        end
      end

      def parsed_licence_schema
        schema_file_path = Rails.root.join("lib/documents/schemas/licence_transactions.json")
        json_blob = File.new(schema_file_path).read
        JSON.parse(json_blob)
      end

      def unrecognised_tags_instructions
        <<~HEREDOC
          Please read the instructions (under heading 'Update tagging') in the following link to resolve the unrecognised
          tags errors: https://trello.com/c/2SBbuD8N/1969-how-to-correct-unrecognised-tags-when-importing-licences
        HEREDOC
      end
    end
  end
end
