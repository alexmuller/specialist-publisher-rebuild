class MockSpikeFinderDocument < Document
  FORMAT_SPECIFIC_FIELDS = %i[
    mock_spike_finder_document_facet_one
    mock_spike_finder_document_facet_two
  ].freeze

  attr_accessor(*FORMAT_SPECIFIC_FIELDS)

  def initialize(params = {})
    super(params, FORMAT_SPECIFIC_FIELDS)
  end

  def self.title
    "Mock Spike Finder Document"
  end

  def primary_publishing_organisation
    "af07d5a5-df63-4ddc-9383-6a666845ebe9"
  end
end
