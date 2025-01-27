class BusinessFinanceSupportScheme < Document
  apply_validations
  validates :continuation_link, presence: true

  FORMAT_SPECIFIC_FIELDS = %i[
    business_sizes
    business_stages
    continuation_link
    industries
    regions
    types_of_support
    will_continue_on
  ].freeze

  attr_accessor(*FORMAT_SPECIFIC_FIELDS)

  def initialize(params = {})
    super(params, FORMAT_SPECIFIC_FIELDS)
  end

  def self.exportable?
    true
  end
end
