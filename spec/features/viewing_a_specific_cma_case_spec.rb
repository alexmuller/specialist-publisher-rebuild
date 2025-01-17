require "spec_helper"

RSpec.feature "Viewing a specific case", type: :feature do
  let(:cma_cases) { [] }
  before do
    log_in_as_editor(:cma_editor)

    stub_publishing_api_has_content(cma_cases, hash_including(document_type: CmaCase.document_type))
    cma_cases.each do |cma_case|
      stub_publishing_api_has_item(cma_case)
    end
  end

  context "from the index" do
    let(:cma_cases) do
      [
        FactoryBot.create(
          :cma_case,
          title: "Example CMA Case",
          description: "This is the summary of example CMA case",
          publication_state: "draft",
          state_history: { "1" => "draft" },
          details: {
            "body" => [
              {
                "content_type" => "text/govspeak",
                "content" => "## Header\r\n\r\nThis is the long body of an example CMA case",
              },
            ],
            "metadata" => {
              "bulk_published" => false,
              "document_type" => "cma_case",
              "opened_date" => "2014-01-01",
              "closed_date" => "2015-01-01",
              "case_type" => "ca98-and-civil-cartels",
              "case_state" => "closed",
              "market_sector" => %w[energy],
              "outcome_type" => "ca98-no-grounds-for-action-non-infringement",
            },
          },
        ),
      ]
    end

    scenario "displays the metadata" do
      visit "/cma-cases"
      find(".govuk-table").find("tr", text: "Example CMA Case").find("a", text: "View").click

      expect(page.status_code).to eq(200)
      expect(page).to have_content("Example CMA Case")
      expect(page).to have_content("draft")
      expect(page).to have_content("This is the summary of example CMA case")
      expect(page).to have_content("This is the long body of an example CMA case")
      expect(page).to have_content("Opened 2014-01-01")
      expect(page).to have_content("Closed 2015-01-01")
      expect(page).to have_content("Outcome CA98 - no grounds for action")
      expect(page).to have_content("Market sector Energy")
      expect(page).to have_content("Bulk published false")
    end
  end

  scenario "that doesn't exist" do
    content_id = "a-case-that-doesnt-exist"
    url = "#{GdsApi::TestHelpers::PublishingApi::PUBLISHING_API_V2_ENDPOINT}/content/#{content_id}"
    stub_request(:get, url)
      .with(query: hash_including(locale: "en"))
      .to_return(status: 404, body: resource_not_found(content_id, "content item").to_json, headers: {})

    visit "/cma-cases/#{content_id}:en"

    expect(page.current_path).to eq("/cma-cases")
    expect(page).to have_content("Document not found")
  end

  context "bulk publishing" do
    let(:cma_cases) do
      [
        FactoryBot.create(
          :cma_case,
          title: "Bulk published CMA Case",
          details: {
            "metadata" => {
              "bulk_published" => true,
            },
          },
        ),
      ]
    end

    scenario "the document has been bulk published" do
      visit "/cma-cases"
      expect(page).to have_content("Bulk published CMA Case")
      find(".govuk-table").find("tr", text: "Bulk published CMA Case").find("a", text: "View").click
      expect(page).to have_content("Bulk published true")
    end
  end

  context "attachments" do
    let(:cma_cases) do
      [
        FactoryBot.create(
          :cma_case,
          title: "CMA Case without attachments",
          details: { attachments: [] },
        ),
        FactoryBot.create(
          :cma_case,
          title: "CMA Case with attachments",
          details: {
            attachments: [
              FactoryBot.create(
                :attachment_payload,
                title: "first attachment",
                created_at: "2015-12-01T10:12:26+00:00",
                updated_at: "2015-12-02T10:12:26+00:00",
              ),
              FactoryBot.create(
                :attachment_payload,
                title: "second attachment",
                created_at: "2015-12-03T10:12:26+00:00",
                updated_at: "2015-12-04T10:12:26+00:00",
              ),
            ],
          },
        ),
      ]
    end

    scenario "Viewing a document without attachments" do
      visit "/cma-cases"
      find(".govuk-table").find("tr", text: "CMA Case without attachments").find("a", text: "View").click

      expect(page).to have_content("This document doesn’t have any attachments")
    end

    scenario "Viewing a document with attachments" do
      visit "/cma-cases"
      find(".govuk-table").find("tr", text: "CMA Case with attachments").find("a", text: "View").click

      expect(page).to have_no_content("This document doesn’t have any attachments")
      expect(page).to have_content("2 attachments")

      expect(page).to have_content("first attachment")
      expect(page).to have_content("1 December 2015")
      expect(page).to have_content("2 December 2015")
      expect(page).to have_content("second attachment")
      expect(page).to have_content("3 December 2015")
      expect(page).to have_content("4 December 2015")
    end
  end

  context "Viewing publication states" do
    let(:cma_cases) do
      [
        FactoryBot.create(
          :cma_case,
          title: "Example Draft",
          publication_state: "draft",
          state_history: { "1" => "draft" },
        ),
        FactoryBot.create(
          :cma_case,
          title: "Example Published",
          publication_state: "published",
          state_history: { "1" => "published" },
        ),
        FactoryBot.create(
          :cma_case,
          title: "Example Unpublished",
          publication_state: "unpublished",
          state_history: { "1" => "unpublished" },
        ),
        FactoryBot.create(
          :cma_case,
          title: "Example Published with new draft",
          publication_state: "draft",
          state_history: {
            "1" => "published",
            "2" => "draft",
          },
        ),
        FactoryBot.create(
          :cma_case,
          title: "Example Unpublished with new draft",
          publication_state: "draft",
          state_history: {
            "1" => "unpublished",
            "2" => "draft",
          },
        ),
        FactoryBot.create(
          :cma_case,
          title: "More states",
          publication_state: "draft",
          state_history: {
            "1" => "unpublished",
            "2" => "published",
            "3" => "draft",
          },
        ),
        FactoryBot.create(
          :cma_case,
          title: "More states Published",
          publication_state: "published",
          state_history: {
            "1" => "unpublished",
            "2" => "published",
          },
        ),
      ]
    end

    scenario "Viewing a document with a draft state" do
      visit "/cma-cases"
      find(".govuk-table").find("tr", text: "Example Draft").find("a", text: "View").click

      expect(page).not_to have_content("View on website")
      expect(page).to have_content("Preview draft")
      within(".metadata-list") do
        expect(page).to have_content("Publication state draft")
      end
    end

    scenario "Viewing a document with a published state" do
      visit "/cma-cases"
      find(".govuk-table").find("tr", text: "Example Published").find("a", text: "View").click

      expect(page).to have_content("View on website")
      expect(page).not_to have_content("Preview draft")
      within(".metadata-list") do
        expect(page).to have_content("Publication state published")
      end

      visit "/cma-cases"
      click_link "More states Published"

      within(".metadata-list") do
        expect(page).to have_content("Publication state published")
      end
    end

    scenario "Viewing a document with an unpublished state" do
      visit "/cma-cases"
      find(".govuk-table").find("tr", text: "Example Unpublished").find("a", text: "View").click

      expect(page).not_to have_content("View on website")
      expect(page).not_to have_content("Preview draft")
      within(".metadata-list") do
        expect(page).to have_content("Publication state unpublished")
      end
    end

    scenario "Viewing a document that has been published and has a new draft" do
      visit "/cma-cases"
      find(".govuk-table").find("tr", text: "Example Published with new draft").find("a", text: "View").click

      expect(page).to have_content("View on website")
      expect(page).to have_content("Preview draft")
      within(".metadata-list") do
        expect(page).to have_content("Publication state published with new draft")
      end

      visit "/cma-cases"
      click_link "More states"

      within(".metadata-list") do
        expect(page).to have_content("Publication state published with new draft")
      end
    end

    scenario "Viewing a document that has been UN-published and has a new draft" do
      visit "/cma-cases"
      find(".govuk-table").find("tr", text: "Example Unpublished with new draft").find("a", text: "View").click

      expect(page).not_to have_content("View on website")
      expect(page).to have_content("Preview draft")
      within(".metadata-list") do
        expect(page).to have_content("Publication state unpublished with new draft")
      end
    end
  end

  context "when a published item exists with the same base path" do
    let(:content_id) { SecureRandom.uuid }
    let(:draft) { FactoryBot.create(:cma_case, content_id:, title: "Example draft", base_path: "/cma-cases/foo") }

    scenario "displays warnings" do
      stub_request(:get, %r{/v2/content/#{content_id}})
        .to_return(status: 200, body: draft.merge(warnings: { "content_item_blocking_publish" => true }).to_json)

      visit "/cma-cases/#{content_id}"

      expect(page).to have_content("Warning: This document's URL is already used on GOV.UK. You can't publish it until you change the title.")
    end
  end
end
