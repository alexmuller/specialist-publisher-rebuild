class MedicalSafetyAlert < Document
  apply_validations
  validates :issued_date, date: true

  FORMAT_SPECIFIC_FIELDS = format_specific_fields

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
