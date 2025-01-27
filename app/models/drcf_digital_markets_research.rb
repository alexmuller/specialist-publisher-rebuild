class DrcfDigitalMarketsResearch < Document
  apply_validations
  validates :digital_market_research_publish_date, date: true

  FORMAT_SPECIFIC_FIELDS = %i[
    digital_market_research_category
    digital_market_research_publisher
    digital_market_research_area
    digital_market_research_topic
    digital_market_research_publish_date
  ].freeze

  attr_accessor(*FORMAT_SPECIFIC_FIELDS)

  def initialize(params = {})
    super(params, FORMAT_SPECIFIC_FIELDS)
  end
end
