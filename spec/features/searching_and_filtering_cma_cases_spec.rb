require "spec_helper"

RSpec.feature "Searching and filtering", type: :feature do
  let(:test_date) { Date.new(2016, 1, 11) }
  let(:cma_cases) do
    ten_example_cases = 10.times.collect do |n|
      FactoryBot.create(
        :cma_case,
        "title" => "Example CMA Case #{n}",
        "description" => "This is the summary of example CMA case #{n}",
        "base_path" => "/cma-cases/example-cma-case-#{n}",
        "publication_state" => "draft",
        "last_edited_at" => (test_date - (n + 1).days).iso8601,
        "public_updated_at" => (test_date - (10 - n).days).iso8601,
      )
    end
    ten_example_cases[1]["publication_state"] = "published"
    ten_example_cases[1]["state_history"] = { "1" => "published" }
    ten_example_cases[2]["publication_state"] = "draft"
    ten_example_cases[2]["state_history"] = { "1" => "published", "2" => "unpublished", "3" => "draft" }
    ten_example_cases
  end

  before do
    log_in_as_editor(:cma_editor)
  end

  scenario "visiting the index of a live finder has a link to 'view on website'" do
    stub_publishing_api_has_content([], hash_including(document_type: CmaCase.document_type))

    visit "/cma-cases"

    expect(page).to have_link("View on website (opens in new tab)", href: "http://www.dev.gov.uk/cma-cases")
  end

  scenario "visiting the index of a draft finder has a link to 'preview draft'" do
    stub_publishing_api_has_content([], hash_including(document_type: CmaCase.document_type))

    allow(CmaCase).to receive(:target_stack).and_return("draft")

    visit "/cma-cases"

    expect(page).to have_link("Preview draft (opens in new tab)", href: "http://draft-origin.dev.gov.uk/cma-cases")
  end

  context "visiting the index with results" do
    before do
      stub_publishing_api_has_content(cma_cases, hash_including(document_type: CmaCase.document_type))
    end

    scenario "viewing the unfiltered items" do
      visit "/cma-cases"

      expect(page.status_code).to eq(200)
      expect(page).to have_selector("li.document", count: 10)
      expect(page).to have_content("Example CMA Case 0")
      expect(page).to have_content("Example CMA Case 1")
      expect(page).to have_content("Example CMA Case 2")
    end

    scenario "viewing the publication state on the index page" do
      visit "/cma-cases"

      within(".document-list li.document:nth-child(1)") do
        expect(page).to have_content("draft")
        expect(page).to have_css(".label-primary")
      end

      within(".document-list li.document:nth-child(2)") do
        expect(page).to have_content("published")
        expect(page).to have_css(".label-default")
      end

      within(".document-list li.document:nth-child(3)") do
        expect(page).to have_content("unpublished with new draft")
        expect(page).to have_css(".label-primary")
      end
    end

    scenario "viewing the last_edited_at field on the index page" do
      Timecop.freeze(test_date) do
        visit "/cma-cases"

        within(".document-list li.document:nth-child(1)") do
          expect(page).to have_content("Updated 1 day ago")
        end

        within(".document-list li.document:nth-child(10)") do
          expect(page).to have_content("Updated 10 days ago")
        end
      end
    end

    scenario "filtering the items with some results returned" do
      stub_publishing_api_has_content([cma_cases.first], hash_including(document_type: CmaCase.document_type, q: "0"))

      visit "/cma-cases"

      expect(page).not_to have_select("Organisation")

      fill_in "Title", with: "0"
      click_button "Filter"
      expect(page).to have_content("Example CMA Case 0")
      expect(page).to have_selector("li.document", count: 1)
    end

    scenario "filtering the items with no results returned" do
      stub_publishing_api_has_content([], hash_including(document_type: CmaCase.document_type, q: "abcdef"))

      visit "/cma-cases"
      fill_in "Title", with: "abcdef"
      click_button "Filter"
      expect(page).to have_content("Your search - abcdef - did not match any documents.")
    end
  end

  context "visiting the index with no results" do
    before do
      stub_publishing_api_has_content([], hash_including(document_type: CmaCase.document_type))
    end

    scenario "viewing the unfiltered items" do
      visit "/cma-cases"

      expect(page.status_code).to eq(200)
      expect(page).to have_content("No CMA Cases available.")
    end
  end

  context "when publishing-api returns null values for last-edited-at" do
    scenario "last-edited-at should be hidden when value is nil" do
      cma_cases_with_missing_last_edited_at = cma_cases.each { |item| item.merge!("last_edited_at" => nil) }
      expect(cma_cases_with_missing_last_edited_at.sample["last_edited_at"]).to eq(nil)

      stub_publishing_api_has_content(cma_cases_with_missing_last_edited_at, hash_including(document_type: CmaCase.document_type))

      visit "/cma-cases"

      expect(page.status_code).to eq(200)
      expect(page).not_to have_css(".last-edited-at")
    end
  end
end
