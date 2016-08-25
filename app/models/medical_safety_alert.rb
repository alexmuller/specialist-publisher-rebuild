class MedicalSafetyAlert < Document
  validates :alert_type, presence: true
  validates :issued_date, presence: true, date: true

  FORMAT_SPECIFIC_FIELDS = %i(
    alert_type
    issued_date
    medical_specialism
  )

  attr_accessor(*FORMAT_SPECIFIC_FIELDS)

  def initialize(params = {})
    super(params, FORMAT_SPECIFIC_FIELDS)
  end

  def self.title
    "Medical Safety Alert"
  end
end
