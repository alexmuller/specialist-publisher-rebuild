class ProductSafetyAlertReportRecall < Document
  apply_validations
  validates :product_recall_alert_date, allow_blank: true, date: true

  FORMAT_SPECIFIC_FIELDS = %i[
    product_alert_type
    product_risk_level
    product_category
    product_measure_type
    product_recall_alert_date
  ].freeze

  attr_accessor(*FORMAT_SPECIFIC_FIELDS)

  def initialize(params = {})
    super(params, FORMAT_SPECIFIC_FIELDS)
  end

  def self.admin_slug
    "product-safety-alerts-reports-recalls"
  end
end
