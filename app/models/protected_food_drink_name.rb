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
  validates :date_registration, presence: true, date: true, allow_blank: true
  validates :time_registration, presence: true, time: true, allow_blank: true
  validates :date_registration_eu, presence: true, date: true, allow_blank: true

  def self.title
    "Protected Geographical Food and Drink Name"
  end

  def self.slug
    "protected-food-drink-names"
  end
end
