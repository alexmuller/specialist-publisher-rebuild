class MarineEquipmentApprovedRecommendation < Document
  validates :year_adopted, format: /\A$|[1-9][0-9]{3}\z/

  FORMAT_SPECIFIC_FIELDS = format_specific_fields

  attr_accessor(*FORMAT_SPECIFIC_FIELDS)

  def initialize(params = {})
    super(params, FORMAT_SPECIFIC_FIELDS)
  end
end
