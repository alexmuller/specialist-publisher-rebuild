class EmploymentTribunalDecision < Document
  apply_validations
  validates :tribunal_decision_decision_date, date: true

  FORMAT_SPECIFIC_FIELDS = %i[
    hidden_indexable_content
    tribunal_decision_categories
    tribunal_decision_country
    tribunal_decision_decision_date
  ].freeze

  attr_accessor(*FORMAT_SPECIFIC_FIELDS)

  def initialize(params = {})
    super(params, FORMAT_SPECIFIC_FIELDS)
  end

  def self.admin_slug
    "employment-tribunal-decisions"
  end
end
