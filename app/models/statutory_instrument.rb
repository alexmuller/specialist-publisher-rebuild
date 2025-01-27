class StatutoryInstrument < Document
  apply_validations
  validates :laid_date, date: true
  validates :sift_end_date, date: true
  validates :sift_end_date, absence: { message: "must be blank when withdrawn" }, if: :withdrawn_sifting_status?
  validates :primary_publishing_organisation, presence: true
  validates :withdrawn_date, presence: true, date: true, if: :withdrawn_sifting_status?
  validates :withdrawn_date, absence: { message: "must be blank if not withdrawn" }, unless: :withdrawn_sifting_status?

  FORMAT_SPECIFIC_FIELDS = format_specific_fields

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

  def withdrawn_sifting_status?
    sifting_status == "withdrawn"
  end
end
