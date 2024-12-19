class IntellectualPropertyTrademarkDecisions
  validates :british_library_number, presence: true
  validates :type_of_hearing, presence: true
  validates :ipo_mark, presence: true
  validates :ipo_class, presence: true
  validates :issued_between, allow_blank: true, date: true
  validates :and, allow_blank: true, date: true
  validates :appointed_person_hearing_officer, presence: true
  validates :person_or_company_involved, presence: true
  validates :grounds_section, presence: true
  validates :grounds_sub_section, presence: true
  validates :browse_by_year, allow_blank: true, date: true
  validates_with OpenBeforeClosedValidator, issued_between: :issued_between, and: :and, browse_by_year: :browse_by_year

  FORMAT_SPECIFIC_FIELDS = %i[
    british_library_number
    type_of_hearing
    mark
    class
    issued_between
    and
    appointed_person_hearing_officer
    person_or_company_involved
    grounds_section
    grounds_sub_section
    browse_by_year
    ].freeze

  attr_accessor(*FORMAT_SPECIFIC_FIELDS)

  def initialize(params = {})
    super(params, FORMAT_SPECIFIC_FIELDS)
  end
end
  