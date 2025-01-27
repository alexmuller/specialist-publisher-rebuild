class CmaCase < Document
  apply_validations
  validates :opened_date, allow_blank: true, date: true
  validates :closed_date, allow_blank: true, date: true
  validates_with OpenBeforeClosedValidator, opened_date: :opened_date, closed_date: :closed_date

  FORMAT_SPECIFIC_FIELDS = %i[
    opened_date
    closed_date
    case_type
    case_state
    market_sector
    outcome_type
  ].freeze

  attr_accessor(*FORMAT_SPECIFIC_FIELDS)

  def initialize(params = {})
    super(params, FORMAT_SPECIFIC_FIELDS)
  end
end
