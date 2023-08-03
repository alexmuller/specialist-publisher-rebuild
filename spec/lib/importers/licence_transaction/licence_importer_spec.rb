require "spec_helper"
require "gds_api/test_helpers/publishing_api"
require "importers/licence_transaction/licence_importer"

RSpec.describe Importers::LicenceTransaction::LicenceImporter do
  let(:new_content_id) { "0cc89dd8-1055-4e6b-8f64-9a772dbe28db" }
  let(:publishing_api_response) { publishing_api_licences_response }
  let(:licence_identifier) { "9150-7-1" }
  let(:tagging_path) { Rails.root.join("spec/support/csvs/valid_licence_and_tagging.csv") }
  let(:invalid_tagging_path) { Rails.root.join("spec/support/csvs/invalid_licence_and_tagging.csv") }

  before do
    allow(SecureRandom).to receive(:uuid).and_return(new_content_id)
    stub_publishing_api_has_content(
      [
        { "title" => "Department for Environment, Food & Rural Affairs", "content_id" => "af07d5a5-df63-4ddc-9383-6a666845ebe1" },
        { "title" => "Department of Health and Social Care", "content_id" => "af07d5a5-df63-4ddc-9383-6a666845ebe2" },
        { "title" => "Home Office", "content_id" => "af07d5a5-df63-4ddc-9383-6a666845ebe3" },
        { "title" => "Scottish Government", "content_id" => "af07d5a5-df63-4ddc-9383-6a666845ebe4" },
        { "title" => "Centre for Environment, Fisheries and Aquaculture Science", "content_id" => "af07d5a5-df63-4ddc-9383-6a666845ebe5" },
      ],
      hash_including(document_type: "organisation"),
    )
  end

  context "when the csv tagging is invalid" do
    it "doesn't migrate licences and outputs an error message" do
      expect { described_class.new(invalid_tagging_path).call }
        .to output(csv_validation_errors_message).to_stdout

      expect(stub_any_publishing_api_put_content).to_not have_been_requested
      expect(stub_any_publishing_api_patch_links).to_not have_been_requested
      expect(stub_any_publishing_api_publish).to_not have_been_requested
    end
  end

  context "when migrating archived licences" do
    before do
      unpublished_licences = [
        publishing_api_licences_response.first.tap { |licence| licence["state"] = "unpublished" },
        publishing_api_licences_response.first.tap do |licence|
          licence["state"] = "unpublished"
          licence["base_path"] = "/archived-licence-not-to-be-restored"
        end,
      ]

      stub_publishing_api_has_content(
        unpublished_licences,
        { document_type: "licence", page: 1, per_page: 600, states: "unpublished" },
      )
      stub_publishing_api_has_links(
        { content_id: "46044b4d-a41b-42c1-882d-8d03e65f24cd", links: publising_api_get_links_response },
      )
      stub_publishing_api_has_content(
        [],
        { document_type: "licence_transaction", page: 1, per_page: 500, states: "published" },
      )
    end

    it "migrates the licences included in the given base_paths list" do
      put_content_request = stub_publishing_api_put_content(
        new_content_id, expected_put_content_payload
      )
      publish_request = stub_publishing_api_publish(
        new_content_id, { update_type: "republish", locale: "en" }
      )
      patch_links_request = stub_publishing_api_patch_links(
        new_content_id, { links: expected_patch_links_payload }
      )

      expect { described_class.new(tagging_path, ["/art-therapist-registration"]).call }
        .to output(successful_import_message).to_stdout

      expect(put_content_request).to have_been_requested
      expect(patch_links_request).to have_been_requested
      expect(publish_request).to have_been_requested
    end

    it "doesn't migrates the licences missing from the given base_paths list" do
      put_content_request = stub_publishing_api_put_content(
        new_content_id, expected_put_content_payload
      )
      publish_request = stub_publishing_api_publish(
        new_content_id, { update_type: "republish", locale: "en" }
      )
      patch_links_request = stub_publishing_api_patch_links(
        new_content_id, { links: expected_patch_links_payload }
      )

      described_class.new(tagging_path, ["/archived-licence-not-to-be-restored"]).call

      expect(put_content_request).to_not have_been_requested
      expect(patch_links_request).to_not have_been_requested
      expect(publish_request).to_not have_been_requested
    end
  end

  context "when a licence is valid" do
    before do
      stub_publishing_api_has_content(
        publishing_api_response,
        { document_type: "licence", page: 1, per_page: 500, states: "published" },
      )
      stub_publishing_api_has_links(
        { content_id: "46044b4d-a41b-42c1-882d-8d03e65f24cd", links: publising_api_get_links_response },
      )
      stub_publishing_api_has_content(
        [],
        { document_type: "licence_transaction", page: 1, per_page: 500, states: "published" },
      )
    end

    it "migrates the licence" do
      put_content_request = stub_publishing_api_put_content(
        new_content_id, expected_put_content_payload
      )
      publish_request = stub_publishing_api_publish(
        new_content_id, { update_type: "republish", locale: "en" }
      )
      patch_links_request = stub_publishing_api_patch_links(
        new_content_id, { links: expected_patch_links_payload }
      )

      expect { described_class.new(tagging_path).call }
        .to output(successful_import_message).to_stdout

      expect(put_content_request).to have_been_requested
      expect(patch_links_request).to have_been_requested
      expect(publish_request).to have_been_requested
    end
  end

  context "when a licence is invalid" do
    let(:publishing_api_response) do
      publishing_api_licences_response.tap { |licences| licences.first["title"] = nil }
    end

    before do
      stub_publishing_api_has_content(
        publishing_api_response,
        { document_type: "licence", page: 1, per_page: 500, states: "published" },
      )
      stub_publishing_api_has_content(
        [],
        { document_type: "licence_transaction", page: 1, per_page: 500, states: "published" },
      )
    end

    it "doesn't migrate the licence" do
      expect { described_class.new(tagging_path).call }
        .to output(invalid_licence_error_message).to_stdout

      expect(stub_any_publishing_api_put_content).to_not have_been_requested
      expect(stub_any_publishing_api_patch_links).to_not have_been_requested
      expect(stub_any_publishing_api_publish).to_not have_been_requested
    end
  end

  context "when a licence is already imported" do
    before do
      stub_publishing_api_has_content(
        publishing_api_response,
        { document_type: "licence", page: 1, per_page: 500, states: "published" },
      )
      stub_publishing_api_has_content(
        publishing_api_existing_licences_response,
        { document_type: "licence_transaction", page: 1, per_page: 500, states: "published" },
      )
    end

    it "doesn't migrate the licence" do
      expect { described_class.new(tagging_path).call }
        .to output(already_imported_licence_message).to_stdout

      expect(stub_any_publishing_api_put_content).to_not have_been_requested
      expect(stub_any_publishing_api_patch_links).to_not have_been_requested
      expect(stub_any_publishing_api_publish).to_not have_been_requested
    end
  end

  context "when a licence isn't present in the tagging file" do
    let(:publishing_api_response) do
      publishing_api_licences_response.tap do |licences|
        licences.first["base_path"] = "/non-existant"
      end
    end

    before do
      stub_publishing_api_has_content(
        publishing_api_response,
        { document_type: "licence", page: 1, per_page: 500, states: "published" },
      )
    end

    it "doesn't migrate the licence" do
      expect { described_class.new(tagging_path).call }
        .to output(licence_doesnt_exist_in_tagging).to_stdout

      expect(stub_any_publishing_api_put_content).to_not have_been_requested
      expect(stub_any_publishing_api_patch_links).to_not have_been_requested
      expect(stub_any_publishing_api_publish).to_not have_been_requested
    end
  end

  def invalid_licence_error_message
    "[ERROR] licence: /find-licences/art-therapist-registration has validation errors: #<ActiveModel::Errors [#<ActiveModel::Error attribute=title, type=blank, options={}>]>\n"
  end

  def successful_import_message
    "Published: /find-licences/art-therapist-registration\n"
  end

  def already_imported_licence_message
    "Skipping as licence: /find-licences/art-therapist-registration is already imported\n"
  end

  def licence_doesnt_exist_in_tagging
    "Missing licences from tagging file: [\"/non-existant\"]\n"
  end

  def csv_validation_errors_message
    <<~HEREDOC
      CSV errors for '/licence-to-abstract-and-or-impound-water-northern-ireland':
      - unrecognised locations: '["northern-ireeeeeland"]'
      - primary publishing organisation doesn't exist: '["Random non-org"]'

      CSV errors for '/consent-for-leaflet-distribution-northern-ireland':
      - primary publishing organisation doesn't exist: '["Government Digital Service"]'

      CSV errors for '/notification-to-process-personal-data':
      - unrecognised industries: '["arts-and-things-and-stuff-recreation"]'
      - primary publishing organisation doesn't exist: '["Government Digital Service"]'
      - organisations don't exist: '["thing", "bing"]'

      Please read the instructions (under heading 'Update tagging') in the following link to resolve the unrecognised
      tags errors: https://trello.com/c/2SBbuD8N/1969-how-to-correct-unrecognised-tags-when-importing-licences
    HEREDOC
  end

  def expected_put_content_payload
    {
      base_path: "/find-licences/art-therapist-registration",
      title: "Art therapist registration",
      description: "You need to register with the Health and Care Professions Council (HCPC) to practise as an art therapist in the UK",
      document_type: "licence_transaction",
      change_note: "Imported from Publisher",
      schema_name: "specialist_document",
      publishing_app: "specialist-publisher",
      rendering_app: "frontend",
      locale: "en",
      phase: "live",
      details: {
        body: [
          {
            content_type: "text/govspeak",
            content: "$!You must register with the Health and Care Professions Council (HCPC) to practise as an art therapist in the UK.$!\r\n\r\nYou must be registered with HCPC to use any of these job titles:\r\n\r\n* art therapist\r\n* art psychotherapist\r\n* drama therapist\r\n* music therapist\r\n\r\n##Fines and penalties\r\n\r\n%You could be fined up to £5,000 if you call yourself an art therapist, art psychotherapist, drama therapist, or music therapist and you're not registered with the HCPC.%\r\n\r\n*[HCPC]: Health and Care Professions Council",
          },
        ],
        metadata: {
          licence_transaction_continuation_link: "http://www.hpc-uk.org/apply",
          licence_transaction_will_continue_on: "the Health and Care Professions Council (HCPC) website",
          licence_transaction_industry: %w[healthcare],
          licence_transaction_location: %w[england wales scotland northern-ireland],
        },
        max_cache_time: 10,
        temporary_update_type: false,
        headers: [
          {
            text: "Fines and penalties",
            level: 2,
            id: "fines-and-penalties",
          },
        ],
      },
      routes: [
        {
          path: "/find-licences/art-therapist-registration",
          type: "prefix",
        },
      ],
      redirects: [],
      update_type: "major",
      links: {
        finder: %w[b8327c0c-a90d-47b6-992b-ea226b4d3306],
        organisations: %w[
          af07d5a5-df63-4ddc-9383-6a666845ebe3
          af07d5a5-df63-4ddc-9383-6a666845ebe2
        ],
        primary_publishing_organisation: %w[af07d5a5-df63-4ddc-9383-6a666845ebe2],
      },
    }
  end

  def expected_patch_links_payload
    {
      organisations: %w[af07d5a5-df63-4ddc-9383-6a666845ebe3 af07d5a5-df63-4ddc-9383-6a666845ebe2],
      primary_publishing_organisation: %w[af07d5a5-df63-4ddc-9383-6a666845ebe2],
      taxons: [],
    }
  end

  def publising_api_get_links_response
    {
      "taxons" => [],
      "available_translations" => %w[welsh],
    }
  end

  def publishing_api_licences_response
    [
      {
        "auth_bypass_ids" => [],
        "base_path" => "/art-therapist-registration",
        "content_store" => "live",
        "description" => "You need to register with the Health and Care Professions Council (HCPC) to practise as an art therapist in the UK",
        "details" => {
          "licence_overview" => [{
            "content" => "$!You must register with the Health and Care Professions Council (HCPC) to practise as an art therapist in the UK.$!\r\n\r\nYou must be registered with HCPC to use any of these job titles:\r\n\r\n* art therapist\r\n* art psychotherapist\r\n* drama therapist\r\n* music therapist\r\n\r\n##Fines and penalties\r\n\r\n%You could be fined up to £5,000 if you call yourself an art therapist, art psychotherapist, drama therapist, or music therapist and you're not registered with the HCPC.%\r\n\r\n*[HCPC]: Health and Care Professions Council",
            "content_type" => "text/govspeak",
          }],
          "will_continue_on" => "the Health and Care Professions Council (HCPC) website",
          "continuation_link" => "http://www.hpc-uk.org/apply",
          "licence_identifier" => licence_identifier,
          "external_related_links" => [],
          "licence_short_description" => "Register as an art therapist with the Health and Care Professions Council (HCPC).",
        },
        "document_type" => "licence",
        "first_published_at" => "2012-09-26T17:08:50Z",
        "phase" => "live",
        "public_updated_at" => "2012-10-16T20:23:44Z",
        "published_at" => "2017-08-31T12:27:39Z",
        "publishing_app" => "publisher",
        "publishing_api_first_published_at" => "2016-04-22T10:40:07Z",
        "publishing_api_last_edited_at" => "2017-08-31T12:27:39Z",
        "redirects" => [],
        "rendering_app" => "frontend",
        "routes" => [{ "path" => "/art-therapist-registration", "type" => "prefix" }],
        "schema_name" => "licence",
        "title" => "Art therapist registration",
        "user_facing_version" => 9,
        "update_type" => "republish",
        "publication_state" => "published",
        "content_id" => "46044b4d-a41b-42c1-882d-8d03e65f24cd",
        "locale" => "en",
        "lock_version" => 10,
        "updated_at" => "2017-08-31T12:27:39Z",
        "state_history" => { "4" => "superseded", "7" => "superseded", "1" => "superseded", "3" => "superseded", "9" => "published", "5" => "superseded", "2" => "superseded", "8" => "superseded", "6" => "superseded" },
        "links" => {},
      },
    ]
  end

  def publishing_api_existing_licences_response
    [
      {
        "auth_bypass_ids" => [],
        "base_path" => "/find-licences/art-therapist-registration",
        "content_store" => "live",
        "description" => "You need to register with the Health and Care Professions Council (HCPC) to practise as an art therapist in the UK",
        "details" => {
          "body" => [
            {
              "content" => "$!You must register with the Health and Care Professions Council (HCPC) to practise as an art therapist in the UK.$!\r\n\r\nYou must be registered with HCPC to use any of these job titles:\r\n\r\n* art therapist\r\n* art psychotherapist\r\n* drama therapist\r\n* music therapist\r\n\r\n##Fines and penalties\r\n\r\n%You could be fined up to £5,000 if you call yourself an art therapist, art psychotherapist, drama therapist, or music therapist and you're not registered with the HCPC.%\r\n\r\n*[HCPC]: Health and Care Professions Council",
              "content_type" => "text/govspeak",
            },
          ],
          "headers" => [
            {
              "id" => "fines-and-penalties", "text" => "Fines and penalties", "level" => 2
            },
          ],
          "metadata" => {
            "licence_transaction_will_continue_on" => "the Health and Care Professions Council (HCPC) website",
            "licence_transaction_continuation_link" => "http://www.hpc-uk.org/apply",
          },
          "max_cache_time" => 10,
          "temporary_update_type" => false,
        },
        "document_type" => "licence_transaction",
        "first_published_at" => "2023-01-18T17:28:50Z",
        "last_edited_at" => "2023-01-18T17:42:02Z",
        "phase" => "live",
        "public_updated_at" => "2023-01-18T17:28:50Z",
        "published_at" => "2023-01-18T17:43:46Z",
        "publishing_app" => "specialist-publisher",
        "publishing_api_first_published_at" => "2023-01-18T17:28:50Z",
        "publishing_api_last_edited_at" => "2023-01-18T17:42:02Z",
        "redirects" => [],
        "rendering_app" => "frontend",
        "routes" => [
          {
            "path" => "/find-licences/art-therapist-registration", "type" => "prefix"
          },
        ],
        "schema_name" => "specialist_document",
        "title" => "Art therapist registration",
        "user_facing_version" => 1,
        "update_type" => "minor",
        "publication_state" => "published",
        "content_id" => "64cbffc0-553a-48cd-8adc-faf2cb080d01",
        "locale" => "en",
        "lock_version" => 1,
        "updated_at" => "2023-01-18T17:43:46Z",
        "state_history" => { "1" => "published" },
        "links" => { "finder" => %w[b8327c0c-a90d-47b6-992b-ea226b4d3306] },
      },
    ]
  end
end
