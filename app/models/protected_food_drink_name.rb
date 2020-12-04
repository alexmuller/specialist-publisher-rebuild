class ProtectedFoodDrinkName < Document
  validates :registered_name, presence: true
  validates :register, presence: true
  validates :status, presence: true
  validates :class_category, presence: true
  validates :protection_type, presence: true
  validates :country_of_origin, presence: true
  validates :traditional_term_grapevine_product_category, presence: true, allow_blank: true
  validates :traditional_term_type, presence: true, allow_blank: true
  validates :traditional_term_language, presence: true, allow_blank: true
  validates :reason_for_protection, presence: true, allow_blank: true
  validates :date_application, presence: true, date: true, allow_blank: true
  validates :date_registration, presence: true, date: true
  validates :date_registration_eu, presence: true, date: true, allow_blank: true

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
    date_registration_eu
    internal_notes
  ].freeze

  attr_accessor(*FORMAT_SPECIFIC_FIELDS)

  def initialize(params = {})
    super(params, FORMAT_SPECIFIC_FIELDS)
  end

  def self.title
    "Protected Geographical Food and Drink Name"
  end

  def self.slug
    "protected-food-drink-names"
  end

  def primary_publishing_organisation
    "de4e9dc6-cca4-43af-a594-682023b84d6c"
  end
end
