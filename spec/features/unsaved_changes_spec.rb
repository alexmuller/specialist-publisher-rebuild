require 'spec_helper'

RSpec.feature "Unsaved changes to a document", type: :feature, js: true do
  let(:message) { "You have unsaved changes that will be lost if you leave this page." }
  let(:cma_case) { FactoryBot.create(:cma_case) }
  let(:content_id) { cma_case['content_id'] }

  before do
    allow(SecureRandom).to receive(:uuid).and_return(content_id)
    stub_any_publishing_api_put_content
    stub_any_publishing_api_patch_links
    publishing_api_has_content([cma_case], hash_including(document_type: CmaCase.document_type))
    publishing_api_has_item(cma_case)

    log_in_as_editor(:cma_editor)
    visit "/cma-cases"
  end

  context "a new document" do
    before do
      click_on "Add another CMA Case"

      fill_in "Title", with: "Example CMA Case"
      fill_in "Summary", with: "This is the summary of an example CMA case"
      fill_in "Body", with: "## Header" + ("\n\nThis is the long body of an example CMA case" * 2)
      fill_in "[cma_case]opened_date(1i)", with: "2014"
      fill_in "[cma_case]opened_date(2i)", with: "01"
      fill_in "[cma_case]opened_date(3i)", with: "01"
      fill_in "[cma_case]closed_date(1i)", with: "2015"
      fill_in "[cma_case]closed_date(2i)", with: "01"
      fill_in "[cma_case]closed_date(3i)", with: "01"
      select "Energy", from: "cma_case_market_sector", visible: false # The hidden select2 select element
    end

    scenario "when an 'Your documents' is clicked and the confirmation is cancelled" do
      dismiss_confirm message do
        click_link "Your documents"
      end

      expect(current_path).to eq("/cma-cases/new")
    end

    scenario "when an 'Your documents' is clicked and the confirmation is accepted" do
      accept_confirm message do
        click_link "Your documents"
      end

      expect(current_path).to eq("/cma-cases")
    end

    scenario "when attempting to close the current window and cancelling the confirmation" do
      dismiss_confirm message do
        page.evaluate_script "window.close();"
      end

      expect(current_path).to eq("/cma-cases/new")
    end

    scenario "when attempting to go back a page and accepting the confirmation" do
      accept_confirm message do
        page.evaluate_script "window.history.back();"
      end

      expect(current_path).to eq("/cma-cases")
    end

    scenario "when attempting to go back a page and cancelling the confirmation" do
      dismiss_confirm message do
        page.evaluate_script "window.history.back();"
      end

      expect(current_path).to eq("/cma-cases/new")
    end

    scenario "when changes are saved" do
      click_button "Save as draft"

      expect(page.status_code).to eq(200)

      within(".alert-success") do
        expect(page).to have_content("Created Example CMA Case")
      end

      click_on "Edit document"
      click_link "Add attachment"

      expect(current_path).to eq("/cma-cases/#{content_id}/attachments/new")
    end
  end

  context "an existing document" do
    before do
      click_on "Example document"
      click_on "Edit document"

      fill_in "Title", with: "Amended example document"
      fill_in "Summary", with: "This is an update to the summary of an example CMA case"
      fill_in "Body", with: "## Header" + ("\n\nThis is the updated body text of an example CMA case" * 2)
      fill_in "[cma_case]opened_date(1i)", with: "2014"
      fill_in "[cma_case]opened_date(2i)", with: "02"
      fill_in "[cma_case]opened_date(3i)", with: "02"
      select "Energy", from: "cma_case_market_sector", visible: false # The hidden select2 select element
    end

    scenario "when an 'Add attachment' is clicked and the confirmation is cancelled" do
      dismiss_confirm message do
        click_link "Add attachment"
      end

      expect(current_path).to eq("/cma-cases/#{content_id}/edit")
    end

    scenario "when an 'Add attachment' is clicked and the confirmation is accepted" do
      accept_confirm message do
        click_link "Add attachment"
      end

      expect(current_path).to eq("/cma-cases/#{content_id}/attachments/new")
    end

    scenario "when attempting to close the current window and cancelling the confirmation" do
      dismiss_confirm message do
        page.evaluate_script "window.close();"
      end

      expect(current_path).to eq("/cma-cases/#{content_id}/edit")
    end

    scenario "when attempting to go back a page and accepting the confirmation" do
      accept_confirm message do
        page.evaluate_script "window.history.back();"
      end

      expect(current_path).to eq("/cma-cases/#{content_id}")
    end

    scenario "when attempting to go back a page and cancelling the confirmation" do
      dismiss_confirm message do
        page.evaluate_script "window.history.back();"
      end

      expect(current_path).to eq("/cma-cases/#{content_id}/edit")
    end

    scenario "when changes are saved" do
      click_button "Save as draft"

      expect(page.status_code).to eq(200)

      within(".alert-success") do
        expect(page).to have_content("Updated Amended example document")
      end

      click_on "Edit document"
      click_link "Add attachment"

      expect(current_path).to eq("/cma-cases/#{content_id}/attachments/new")
    end
  end
end
