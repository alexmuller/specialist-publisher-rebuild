class AaibReport < Document
  validates :date_of_occurrence, presence: true, date: true, unless: ->(report) {
    report.report_type == "safety-study" && report.date_of_occurrence.blank?
  }

  FORMAT_SPECIFIC_FIELDS = %i(
    date_of_occurrence
    aircraft_category
    report_type
    location
    aircraft_type
    registration
  )

  attr_accessor(*FORMAT_SPECIFIC_FIELDS)

  def initialize(params = {})
    super(params, FORMAT_SPECIFIC_FIELDS)
  end

  def self.title
    "AAIB Report"
  end
end
