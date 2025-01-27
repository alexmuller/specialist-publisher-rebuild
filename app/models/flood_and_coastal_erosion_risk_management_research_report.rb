class FloodAndCoastalErosionRiskManagementResearchReport < Document
  apply_validations
  validates :date_of_completion, date: true
  validates :date_of_start, date: true
  validates :primary_publishing_organisation, presence: true

  FORMAT_SPECIFIC_FIELDS = %i[
    flood_and_coastal_erosion_category
    date_of_completion
    date_of_start
    project_code
    project_status
    topics
  ].freeze

  attr_accessor(*FORMAT_SPECIFIC_FIELDS, :organisations, :primary_publishing_organisation)

  def initialize(params = {})
    super(params, FORMAT_SPECIFIC_FIELDS)
    @primary_publishing_organisation = params[:primary_publishing_organisation]
    @organisations = params[:organisations]
  end

  def links
    super.merge(
      organisations: organisations | [primary_publishing_organisation],
      primary_publishing_organisation: [primary_publishing_organisation],
    )
  end

  def self.has_organisations?
    true
  end
end
