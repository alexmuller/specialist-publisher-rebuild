RSpec.shared_examples "it saves payloads that are valid against the 'specialist_document' schema" do
  describe "#save!" do
    it "saves a valid document" do
      publishing_api_has_item(payload)
      Timecop.freeze(Time.parse("2015-12-18 10:12:26 UTC"))
      stub_any_publishing_api_put_content
      stub_any_publishing_api_patch_links

      instance = described_class.find(payload["content_id"])
      instance.save!

      expected_payload_sent_to_publishing_api = saved_for_the_first_time(write_payload(payload))

      assert_publishing_api_put_content(instance.content_id, expected_payload_sent_to_publishing_api)
      expect(expected_payload_sent_to_publishing_api.to_json).to be_valid_against_schema('specialist_document')
    end
  end
end
