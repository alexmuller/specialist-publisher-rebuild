class AsylumSupportDecision < Document
  apply_validations
  validates :tribunal_decision_decision_date, date: true
  validates :tribunal_decision_sub_categories, asylum_support_decision_sub_category: true

  FORMAT_SPECIFIC_FIELDS = format_specific_fields

  attr_accessor(*FORMAT_SPECIFIC_FIELDS)

  def initialize(params = {})
    super(params, FORMAT_SPECIFIC_FIELDS)
  end
end
