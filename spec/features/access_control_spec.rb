require "spec_helper"

RSpec.feature "Access control", type: :feature do
  context "as an editor of an organisation that doesn't have access to the application" do
    before do
      log_in_as_editor(:incorrect_id_editor)
    end

    scenario "visiting homepage shows a permissions error" do
      visit "/"

      expect(page.status_code).to eq(200)
      expect(page).to have_content("Sorry, you don't have permission to access this application")
      expect(page).to have_content("Please contact your main GDS contact if you need access.")
    end
  end

  context "as a CMA Editor" do
    before do
      stub_publishing_api_has_content([], hash_including(document_type: CmaCase.document_type))
      stub_publishing_api_has_content([], hash_including(document_type: Organisation.document_type))
      log_in_as_editor(:cma_editor)
    end

    scenario "visiting /cma-cases is allowed" do
      visit "/cma-cases"

      expect(page.status_code).to eq(200)
      expect(page).to have_content("CMA Cases")
    end

    scenario "visiting admin/cma-cases is allowed" do
      visit "admin/cma-cases"

      expect(page.status_code).to eq(200)
      expect(page).to have_content("CMA Case finder")
    end

    scenario "visiting /aaib-reports is rejected" do
      visit "/aaib-reports"

      expect(page.current_path).to eq("/cma-cases")
      expect(page).to have_content("You aren't permitted to access AAIB Reports")
    end

    scenario "visiting admin/aaib-reports is rejected" do
      visit "admin/aaib-reports"

      expect(page.current_path).to eq("/cma-cases")
      expect(page).to have_content("You aren't permitted to access AAIB Reports")
    end

    scenario "visiting a format which doesn't exist gives an error message" do
      visit "/a-format-which-doesnt-exist"

      expect(page.current_path).to eq("/cma-cases")
      expect(page).to have_content("That format doesn't exist.")
    end
  end
end
