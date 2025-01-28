require "spec_helper"
require "gds_api/test_helpers/support_api"

RSpec.feature "Generating a new finder", type: :feature do
  include GdsApi::TestHelpers::SupportApi

  let(:organisations) do
    [
      { "content_id" => "abc123", "title" => "Some other org" },
    ]
  end

  before do
    log_in_as_editor(:gds_editor)
    stub_publishing_api_has_content(organisations, hash_including(document_type: Organisation.document_type))
    stub_any_support_api_call
  end

  scenario "visiting the empty form" do
    visit "admin/new"

    expect(page).to_not have_selector(".govuk-details")
    expect(page).to have_selector("form[action='/admin/new'][method='post']")
    expect(page).to have_button("Generate schema")
  end

  scenario "submitting the filled in form and seeing a generated schema and retained inputs" do
    visit "admin/new"

    fill_in("Title of the finder", with: "Some title")
    choose "Yes. Allow users to sign up for updates using a signup link."
    fill_in("Signup link", with: "https://example.com/signup")
    click_button("Generate schema")

    expect(page).to have_selector(".govuk-details")
    expect(page).to have_field("Title of the finder", with: "Some title")
    expect(page).to have_field("Signup link", with: "https://example.com/signup")
  end
end
