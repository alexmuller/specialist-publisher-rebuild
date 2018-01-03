require 'spec_helper'

RSpec.describe EmailAlertPresenter do
  let(:cma_case_payload) { FactoryBot.create(:cma_case) }
  let(:medical_safety_payload) { FactoryBot.create(:medical_safety_alert) }
  let(:cma_case_redrafted_payload) { FactoryBot.create(:cma_case, :redrafted, title: "updated") }

  describe "#to_json" do
    context "any finders document" do
      before do
        publishing_api_has_item(cma_case_payload)
        publishing_api_has_item(cma_case_redrafted_payload)
      end

      it "has correct information" do
        cma_case = CmaCase.find(cma_case_payload["content_id"])
        email_alert_presenter = EmailAlertPresenter.new(cma_case)
        presented_data = email_alert_presenter.to_json

        redrafted_cma_case = CmaCase.find(cma_case_redrafted_payload["content_id"])
        email_alert_presenter_redrafted = EmailAlertPresenter.new(redrafted_cma_case)
        presented_data_redrafted = email_alert_presenter_redrafted.to_json

        expect(presented_data[:title]).to include(cma_case_payload["title"])
        expect(presented_data[:description]).to include(cma_case_payload["description"])
        expect(presented_data[:subject]).to include(cma_case_payload["title"])
        expect(presented_data[:subject]).not_to include("updated")
        expect(presented_data_redrafted[:subject]).to include("updated")
        expect(presented_data[:body]).to include(cma_case_payload["description"])
        expect(presented_data[:body]).to include(cma_case_payload["title"])
        expect(presented_data[:body]).to include("For further information on this published case")
        expect(presented_data_redrafted[:body]).to include("For further information on this updated case")
        expect(presented_data[:tags][:format]).to eq(cma_case_payload["document_type"])
        expect(presented_data[:tags][:case_type]).to eq(cma_case_payload["details"]["metadata"]["case_type"])
        expect(presented_data[:document_type]).to eq(cma_case_payload["document_type"])
        expect(presented_data[:public_updated_at]).to include(cma_case_payload["public_updated_at"])
        expect(presented_data[:base_path]).to include(cma_case_payload["base_path"])
        expect(presented_data[:footer]).to include("SUBSCRIBER_PREFERENCES_URL")
        expect(presented_data[:header]).to include("govuk-email-header")

        expect(presented_data.keys).to match_array(%i(
          title description change_note subject body tags document_type
          email_document_supertype government_document_supertype content_id
          public_updated_at publishing_app base_path urgent header footer
        ))
      end
    end

    context "Medical Safety Alerts documents" do
      let(:mhra_email_address) { "email.support@mhra.gov.uk" }

      before do
        publishing_api_has_item(medical_safety_payload)
      end

      it "should use template that contains the email address of MHRA" do
        medical_safety_alert = MedicalSafetyAlert.find(medical_safety_payload["content_id"])
        email_alert_presenter = EmailAlertPresenter.new(medical_safety_alert)
        presented_data = email_alert_presenter.to_json

        expect(presented_data[:body]).to include(mhra_email_address)
        expect(presented_data[:document_type]).to eq("medical_safety_alert")
      end
    end
  end
end
