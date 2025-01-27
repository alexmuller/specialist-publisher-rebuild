class ExportHealthCertificate < Document
  apply_validations

  FORMAT_SPECIFIC_FIELDS = %i[
    certificate_status
    commodity_type
    destination_country
  ].freeze

  attr_accessor(*FORMAT_SPECIFIC_FIELDS)

  def initialize(params = {})
    super(params, FORMAT_SPECIFIC_FIELDS)
  end
end
