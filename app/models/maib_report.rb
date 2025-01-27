class MaibReport < Document
  apply_validations
  validates :date_of_occurrence, date: true

  FORMAT_SPECIFIC_FIELDS = %i[
    date_of_occurrence
    report_type
    vessel_type
  ].freeze

  attr_accessor(*FORMAT_SPECIFIC_FIELDS)

  def initialize(params = {})
    super(params, FORMAT_SPECIFIC_FIELDS)
  end
end
