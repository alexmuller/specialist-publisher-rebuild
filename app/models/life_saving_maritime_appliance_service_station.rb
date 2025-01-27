class LifeSavingMaritimeApplianceServiceStation < Document
  validates :life_saving_maritime_appliance_service_station_regions, presence: true
  validates :life_saving_maritime_appliance_manufacturer, presence: true

  FORMAT_SPECIFIC_FIELDS = %i[
    life_saving_maritime_appliance_service_station_regions
    life_saving_maritime_appliance_manufacturer
    life_saving_maritime_appliance_type
  ].freeze

  attr_accessor(*FORMAT_SPECIFIC_FIELDS)

  def initialize(params = {})
    super(params, FORMAT_SPECIFIC_FIELDS)
  end
end
