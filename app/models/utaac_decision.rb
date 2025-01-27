class UtaacDecision < Document
  apply_validations
  validates :tribunal_decision_decision_date, date: true

  FORMAT_SPECIFIC_FIELDS = %i[
    hidden_indexable_content
    tribunal_decision_categories
    tribunal_decision_decision_date
    tribunal_decision_judges
    tribunal_decision_sub_categories
  ].freeze

  attr_accessor(*FORMAT_SPECIFIC_FIELDS)

  def initialize(params = {})
    super(params, FORMAT_SPECIFIC_FIELDS)
  end
end
