class DrcfDigitalMarketsResearch < Document
  validates :digital_market_research_category, presence: true
  validates :digital_market_research_publisher, presence: true
  validates :digital_market_research_area, presence: true
  validates :digital_market_research_topic, presence: true
  validates :digital_market_research_publish_date,
            presence: true,
            date: true

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

  def self.title
    "DRCF digital markets research"
  end

  def primary_publishing_organisation
    "957eb4ec-089b-4f71-ba2a-dc69ac8919ea"
  end
end
