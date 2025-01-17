require "spec_helper"

RSpec.feature "Viewing a Licence", type: :feature do
  let(:licence_transaction) { FactoryBot.create(:licence_transaction) }
  let(:content_id)          { licence_transaction["content_id"] }
  let(:organisations) do
    [
      { "content_id" => "6de6b795-9d30-4bd8-a257-ab9a6879e1ea", "title" => "PPO Org" },
      { "content_id" => "d31d9806-2644-4023-be70-5376cae84a06", "title" => "Other Org" },
    ]
  end

  before do
    log_in_as_editor(:licence_transaction_editor)
    allow(SecureRandom).to receive(:uuid).and_return(content_id)

    stub_publishing_api_has_content([licence_transaction], hash_including(document_type: LicenceTransaction.document_type))
    stub_publishing_api_has_item(licence_transaction)
    stub_publishing_api_has_content(organisations, hash_including(document_type: Organisation.document_type))
  end

  scenario "has organisation metadata" do
    visit "/licences"
    find(".govuk-table").find("tr", text: "Example document").find("a", text: "View").click
    expect(page.status_code).to eq(200)
    expect(page).to have_content("PPO Org")
    expect(page).to have_content("Other Org")
  end
end
