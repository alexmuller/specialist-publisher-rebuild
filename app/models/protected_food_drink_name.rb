class ProtectedFoodDrinkName < Document
  apply_validations
  validates :date_application, date: true
  validates :date_registration, date: true
  validates :time_registration, time: true
  validates :date_registration_eu, date: true

  FORMAT_SPECIFIC_FIELDS = format_specific_fields

  attr_accessor(*FORMAT_SPECIFIC_FIELDS)

  def initialize(params = {})
    super(params, FORMAT_SPECIFIC_FIELDS)
  end

  def self.admin_slug
    "protected-food-drink-names"
  end
end
