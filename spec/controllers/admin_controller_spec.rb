require "spec_helper"
require "gds_api/test_helpers/support_api"

RSpec.describe AdminController, type: :controller do
  include GdsApi::TestHelpers::SupportApi

  render_views

  let(:user) { FactoryBot.create(:gds_editor) }

  before do
    log_in_as user
  end

  describe "GET new finder form" do
    it "responds successfully" do
      stub_publishing_api_has_content([], hash_including(document_type: Organisation.document_type))
      get :new
      expect(response.status).to eq(200)
    end
  end

  describe "POST new finder form" do
    it "responds successfully" do
      stub_publishing_api_has_content([], hash_including(document_type: Organisation.document_type))
      post :new, params: { email_alert_type: "foo" }
      expect(response.status).to eq(200)
    end
  end

  describe "GET summary" do
    it "responds successfully" do
      stub_publishing_api_has_content([], hash_including(document_type: Organisation.document_type))
      get :summary, params: { document_type_slug: "asylum-support-decisions" }
      expect(response.status).to eq(200)
      within "form" do
        assert_select "textarea[name=\"editorial_remark\"]"
      end
    end
  end

  describe "GET edit metadata" do
    it "responds successfully" do
      stub_publishing_api_has_content([], hash_including(document_type: Organisation.document_type))
      get :edit_metadata, params: { document_type_slug: "asylum-support-decisions" }
      expect(response.status).to eq(200)
    end
  end

  describe "GET edit facets" do
    it "responds successfully" do
      stub_publishing_api_has_content([], hash_including(document_type: Organisation.document_type))
      get :edit_facets, params: { document_type_slug: "asylum-support-decisions" }
      expect(response.status).to eq(200)
    end
  end

  describe "POST edit metadata" do
    it "responds successfully" do
      stub_publishing_api_has_content([], hash_including(document_type: Organisation.document_type))
      post :edit_metadata, params: { document_type_slug: "asylum-support-decisions" }
      expect(response.status).to eq(200)
    end
  end

  describe "POST edit facets" do
    it "responds successfully" do
      stub_publishing_api_has_content([], hash_including(document_type: Organisation.document_type))
      post :edit_facets, params: { document_type_slug: "asylum-support-decisions" }
      expect(response.status).to eq(200)
    end
  end

  describe "POST zendesk" do
    it "sends the expected JSON payload to the Support API" do
      stub_post = stub_support_api_valid_raise_support_ticket(anything)
      captured_body = nil
      WebMock.after_request do |request_signature, _response|
        if request_signature.uri.to_s.include? "/support-tickets"
          captured_body = request_signature.body
        end
      end

      editorial_remark = "This is a high priority request."

      post :zendesk, params: {
        document_type_slug: "cma-cases",
        proposed_schema: "{ \"foo\": \"bar\" }",
        editorial_remark:,
      }

      expected_payload = {
        subject: "Specialist Finder Edit Request: CMA Cases",
        tags: %w[specialist_finder_edit_request],
        priority: "normal",
        description: "Developer - raise a PR replacing this schema with the schema below: " \
          "https://github.com/alphagov/specialist-publisher/edit/main/lib/documents/schemas/cma_cases.json" \
          "\r\n---\r\n" \
          "```\r\n{ \"foo\": \"bar\" }\r\n```",
        requester: {
          name: user.name,
          email: user.email,
        },
        editorial_remark:,
      }.to_json

      assert_requested(stub_post)
      expect(captured_body).to eq(expected_payload)
    end

    it "informs user if there was a failure creating the Zendesk ticket" do
      stub_post = stub_support_api_invalid_raise_support_ticket(anything)

      post :zendesk, params: { document_type_slug: "cma-cases", proposed_schema: CmaCase.finder_schema.to_json }

      assert_requested(stub_post)
      expect(response.status).to eq(302)
      expect(flash[:danger]).to eq("There was an error submitting your request. Please try again.")
    end
  end
end
