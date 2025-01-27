class TrafficCommissionerRegulatoryDecision < Document
  apply_validations
  validates :first_published_at, date: true

  FORMAT_SPECIFIC_FIELDS = %i[
    decision_subject
    regions
    case_type
    outcome_type
    first_published_at
  ].freeze

  attr_accessor(*FORMAT_SPECIFIC_FIELDS)

  def initialize(params = {})
    super(params, FORMAT_SPECIFIC_FIELDS)
  end
end
