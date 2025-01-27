class MedicalSafetyAlert < Document
  apply_validations
  validates :issued_date, date: true

  FORMAT_SPECIFIC_FIELDS = %i[
    alert_type
    issued_date
    medical_specialism
  ].freeze

  attr_accessor(*FORMAT_SPECIFIC_FIELDS)

  def initialize(params = {})
    super(params, FORMAT_SPECIFIC_FIELDS)
  end

  def urgent
    true
  end

  def email_footnote
    "If you have any questions about the medical content in this email, contact MHRA on info@mhra.gov.uk"
  end
end
