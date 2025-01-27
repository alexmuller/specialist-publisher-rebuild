class CmaCase < Document
  apply_validations
  validates :opened_date, allow_blank: true, date: true
  validates :closed_date, allow_blank: true, date: true
  validates_with OpenBeforeClosedValidator, opened_date: :opened_date, closed_date: :closed_date

  FORMAT_SPECIFIC_FIELDS = format_specific_fields

  attr_accessor(*FORMAT_SPECIFIC_FIELDS)

  def initialize(params = {})
    super(params, FORMAT_SPECIFIC_FIELDS)
  end
end
