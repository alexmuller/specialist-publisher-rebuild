require 'spec_helper'
require 'models/valid_against_schema'

RSpec.describe UtaacDecision do
  let(:payload) { FactoryBot.create(:utaac_decision) }
  include_examples "it saves payloads that are valid against the 'specialist_document' schema"

  it 'is not exportable' do
    expect(described_class).not_to be_exportable
  end
end
