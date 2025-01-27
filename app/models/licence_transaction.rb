class LicenceTransaction < Document
  FORMAT_SPECIFIC_FIELDS = %i[
    licence_transaction_continuation_link
    licence_transaction_industry
    licence_transaction_licence_identifier
    licence_transaction_location
    licence_transaction_will_continue_on
  ].freeze

  CUSTOM_ERROR_MESSAGE_FIELDS = FORMAT_SPECIFIC_FIELDS + %i[
    primary_publishing_organisation
    body
    title
    summary
    update_type
    change_note
  ]

  apply_validations
  validates_with LinkOrIdentifierValidator
  validates :primary_publishing_organisation, presence: true
  validates :licence_transaction_licence_identifier, format: {
    with: /\A[0-9]{3,4}-[1-7]-[1-9]\z/,
    allow_blank: true,
  }
  validates :licence_transaction_licence_identifier, licence_identifier_unique: true
  validates :licence_transaction_continuation_link, format: {
    with: URI::DEFAULT_PARSER.make_regexp(%w[http https]),
    allow_blank: true,
  }

  attr_accessor(*FORMAT_SPECIFIC_FIELDS, :organisations, :primary_publishing_organisation)

  def initialize(params = {})
    super(params, FORMAT_SPECIFIC_FIELDS)
    @primary_publishing_organisation = params[:primary_publishing_organisation]
    @organisations = params[:organisations]
  end

  def self.has_organisations?
    true
  end

  def links
    super.merge(
      organisations: organisations | [primary_publishing_organisation],
      primary_publishing_organisation: [primary_publishing_organisation],
    )
  end

  def route_type
    "prefix"
  end

  def self.admin_slug
    "licences"
  end

  def rendering_app
    "frontend"
  end

  def custom_error_message_fields
    CUSTOM_ERROR_MESSAGE_FIELDS
  end
end
