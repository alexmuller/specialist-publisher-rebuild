class MaibReport < Document
  validates :date_of_occurrence, presence: true, date: true

  FORMAT_SPECIFIC_FIELDS = %i(
    date_of_occurrence
    report_type
    vessel_type
  )

  attr_accessor(*FORMAT_SPECIFIC_FIELDS)

  def initialize(params = {})
    super(params, FORMAT_SPECIFIC_FIELDS)
  end

  def self.title
    "MAIB Report"
  end
end
