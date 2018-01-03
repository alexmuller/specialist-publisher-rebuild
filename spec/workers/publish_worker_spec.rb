require "rails_helper"

RSpec.describe PublishWorker do
  let(:document) { FactoryBot.create(:utaac_decision) }
  let(:content_id) { document["content_id"] }

  let(:uses_publish_update_type) {
    request_json_includes("update_type" => "major")
  }

  before do
    stub_any_publishing_api_call

    publishing_api_has_item(document)
  end

  context "when the publication_state is 'draft'" do
    let(:document) {
      FactoryBot.create(:utaac_decision, :draft)
    }

    it "publishes the document" do
      expect_any_instance_of(Document).to receive(:publish)
      subject.perform(content_id)
    end
  end

  context "when the document is in any other state" do
    let(:document) {
      FactoryBot.create(:utaac_decision, :published)
    }

    it "does not publish the document" do
      expect_any_instance_of(Document).not_to receive(:publish)

      expect {
        subject.perform(content_id)
      }.to output(/Skipped publishing/).to_stdout
    end
  end
end
