class ResidentialPropertyTribunalDecision < Document
  apply_validations
  validates :tribunal_decision_sub_category, residential_property_tribunal_decision_sub_category: true
  validates :tribunal_decision_decision_date, date: true

  FORMAT_SPECIFIC_FIELDS = %i[
    hidden_indexable_content
    tribunal_decision_category
    tribunal_decision_sub_category
    tribunal_decision_decision_date
  ].freeze

  attr_accessor(*FORMAT_SPECIFIC_FIELDS)

  def initialize(params = {})
    super(params, FORMAT_SPECIFIC_FIELDS)
  end
end
