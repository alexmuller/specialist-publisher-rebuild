class TrafficCommissionerRegulatoryDecision < Document
  apply_validations
  validates :first_published_at, date: true

  FORMAT_SPECIFIC_FIELDS = format_specific_fields

  attr_accessor(*FORMAT_SPECIFIC_FIELDS)

  def initialize(params = {})
    super(params, FORMAT_SPECIFIC_FIELDS)
  end
end
