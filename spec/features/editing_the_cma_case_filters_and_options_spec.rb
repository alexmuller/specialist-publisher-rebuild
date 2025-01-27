require "spec_helper"
require "gds_api/test_helpers/support_api"

RSpec.feature "Editing the CMA case finder filters and options", type: :feature do
  include GdsApi::TestHelpers::SupportApi

  let(:organisations) do
    [
      { "content_id" => "957eb4ec-089b-4f71-ba2a-dc69ac8919ea", "title" => "Competition and Markets Authority" },
    ]
  end

  before do
    Capybara.current_driver = Capybara.javascript_driver
    log_in_as_editor(:cma_editor)
    stub_publishing_api_has_content([], hash_including(document_type: CmaCase.document_type))
    stub_publishing_api_has_content(organisations, hash_including(document_type: Organisation.document_type))
    stub_any_support_api_call
  end

  scenario "editing, deleting and adding new filters" do
    visit "admin/cma-cases"
    within "#facets_summary_card" do
      click_link "Request changes"
    end

    expect(page).to have_selector("span", text: "CMA Case finder")
    expect(page).to have_selector("h1", text: "Request change: Filters and options")

    # Delete all but the first filter
    all(".js-add-another__remove-button").last.click while all(".js-add-another__remove-button").count > 1

    # Edit one of the fields of the first filter
    fill_in "facets[0][preposition]", with: "foo"

    # Create a new filter, using all of the inputs
    click_button "Add another filter"
    # The new facet inserts at "previous count -1 + 1 == 6",
    # rather than "current total -1 + 1 == 1" as might be expected.
    # This is because the previous facets are still there in the DOM,
    # just hidden and with `_destroy=1`
    inserted_facet = "facets[6]"
    fill_in "#{inserted_facet}[name]", with: "New filter"
    fill_in "#{inserted_facet}[short_name]", with: "short name"
    select "One option", from: "#{inserted_facet}[type]"
    fill_in "#{inserted_facet}[allowed_values]", with: "foo\nbar"
    # TODO: unsure why the 'visible: false' is necessary below. The radio buttons should be (and are) visible.
    choose "#{inserted_facet}[filterable]", option: "false", visible: false
    choose "#{inserted_facet}[display_as_result_metadata]", option: "false", visible: false
    fill_in "#{inserted_facet}[preposition]", with: "of type NEW"

    within find("fieldset", text: "Filter 2") do
      check "Required", visible: false
    end

    click_button "Submit changes"

    expect(page).to have_selector(".govuk-summary-list__row", text: "Case type Updated (click on 'View diff' for details)")
    expect(page).to have_selector(".govuk-summary-list__row", text: "New filter Added (click on 'View diff' for details)")
    expect(page).to have_selector(".govuk-summary-list__row", text: "Case state Deleted")
    expect(page).to have_selector(".govuk-summary-list__row", text: "Market sector Deleted")
    expect(page).to have_selector(".govuk-summary-list__row", text: "Outcome Deleted")
    expect(page).to have_selector(".govuk-summary-list__row", text: "Opened Deleted")
    expect(page).to have_selector(".govuk-summary-list__row", text: "Closed Deleted")
    expect(page).to have_selector("details summary", text: "View diff")
    expect(page).to have_selector("details summary", text: "View generated schema")

    click_button "Submit changes"
    expect(page).to have_selector(".gem-c-success-alert__message", text: "Your changes have been submitted and Zendesk ticket created.")
  end

  scenario "the generated schema is outputted to a hidden input ready for form submission" do
    visit "admin/facets/cma-cases"
    click_button "Submit changes"
    hidden_input = find("[name=proposed_schema]", visible: false)
    expect(hidden_input.value).to eq(JSON.pretty_generate(JSON.parse(CmaCase.finder_schema.to_json)))
  end
end
