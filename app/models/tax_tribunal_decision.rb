class TaxTribunalDecision < Document
  validates :tribunal_decision_category, presence: true
  validates :tribunal_decision_decision_date, allow_blank: true, date: true

  FORMAT_SPECIFIC_FIELDS = %i(
    hidden_indexable_content
    tribunal_decision_category
    tribunal_decision_decision_date
  )

  attr_accessor(*FORMAT_SPECIFIC_FIELDS)

  def initialize(params = {})
    super(params, FORMAT_SPECIFIC_FIELDS)
  end

  def self.title
    "Tax Tribunal Decision"
  end
end
