class ProtectedFoodDrinkName < Document
  apply_validations
  validates :date_application, date: true
  validates :date_registration, date: true
  validates :time_registration, time: true
  validates :date_registration_eu, date: true

  FORMAT_SPECIFIC_FIELDS = %i[
    registered_name
    register
    status
    class_category
    protection_type
    country_of_origin
    traditional_term_grapevine_product_category
    traditional_term_type
    traditional_term_language
    reason_for_protection
    date_application
    date_registration
    time_registration
    date_registration_eu
    internal_notes
  ].freeze

  attr_accessor(*FORMAT_SPECIFIC_FIELDS)

  def initialize(params = {})
    super(params, FORMAT_SPECIFIC_FIELDS)
  end

  def self.admin_slug
    "protected-food-drink-names"
  end
end
