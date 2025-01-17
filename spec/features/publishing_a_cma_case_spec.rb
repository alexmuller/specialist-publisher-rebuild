require "spec_helper"

RSpec.feature "Publishing a CMA case", type: :feature do
  let(:content_id) { item["content_id"] }
  let(:publish_alert_message) { page.find_button("Publish")["data-message"] }
  let(:publish_disable_with_message) { page.find_button("Publish")["data-disable-with"] }

  before do
    Timecop.freeze(Time.zone.parse("2015-12-03T16:59:13+00:00"))
    log_in_as_editor(:cma_editor)

    stub_publishing_api_has_content([item], hash_including(document_type: CmaCase.document_type))
    stub_publishing_api_has_item(item)

    stub_any_publishing_api_put_content
    stub_any_publishing_api_patch_links
    stub_publishing_api_publish(content_id, {})
    stub_email_alert_api_accepts_content_change
  end

  after do
    Timecop.return
  end

  context "when the document is a new draft" do
    let(:item) do
      FactoryBot.create(
        :cma_case,
        title: "Example CMA Case",
        base_path: "/cma-cases/example-cma-case",
        public_updated_at: "2015-11-16T11:53:30+00:00",
        publication_state: "draft",
      )
    end

    let(:published_item) do
      FactoryBot.create(
        :cma_case,
        :published,
        content_id:,
        title: "Example CMA Case",
        base_path: "/cma-cases/example-cma-case",
        public_updated_at: "2015-11-16T11:53:30+00:00",
      )
    end

    scenario "from the index" do
      visit "/cma-cases"
      expect(page.status_code).to eq(200)

      find(".govuk-table").find("tr", text: "Example CMA Case").find("a", text: "View").click
      expect(page.status_code).to eq(200)
      expect(page).to have_content("Example CMA Case")

      stub_publishing_api_has_item_in_sequence(content_id, [item, published_item])

      expect(AttachmentRestoreWorker).not_to receive(:perform_async)

      click_button "Publish"
      expect(page.status_code).to eq(200)
      expect(page).to have_content("Published Example CMA Case")

      changed_json = { "change_note" => "First published." }

      assert_publishing_api_put_content(content_id, request_json_includes(changed_json))

      assert_publishing_api_publish(content_id)
      assert_email_alert_api_content_change_created
    end

    scenario "publish warning and popup text will indicate that an email will be sent" do
      visit "/cma-cases"

      expect(page.status_code).to eq(200)

      find(".govuk-table").find("tr", text: "Example CMA Case").find("a", text: "View").click

      expect(page.status_code).to eq(200)
      expect(page).to have_content("Example CMA Case")
      expect(page).to have_content("Publishing will email subscribers to CMA Cases.")

      expect(publish_alert_message).to eq("Publishing will email subscribers to CMA Cases. Continue?")
      expect(publish_disable_with_message).to eq("Publishing...")
    end

    scenario "writers don't see a publish button" do
      log_in_as_editor(:cma_writer)

      visit "/cma-cases"
      find(".govuk-table").find("tr", text: "Example CMA Case").find("a", text: "View").click

      expect(page).to have_no_selector(:button, "Publish")
      expect(page).to have_content("You don't have permission to publish this document.")
    end
  end

  context "when the document is already published" do
    let(:item) do
      FactoryBot.create(
        :cma_case,
        :published,
        title: "Live Item",
      )
    end

    scenario "publish buttons aren't shown" do
      visit "/cma-cases"
      expect(page.status_code).to eq(200)

      find(".govuk-table").find("tr", text: "Live Item").find("a", text: "View").click

      expect(page).to have_no_selector(:button, "Publish")
      expect(page).to have_content("There are no changes to publish.")
    end
  end

  context "when there is a redrafted document with a major update" do
    let(:item) do
      FactoryBot.create(
        :cma_case,
        :redrafted,
        title: "Major Update Case",
      )
    end

    scenario "publish warning and popup text will indicate that it is a major edit" do
      visit "/cma-cases"

      expect(page.status_code).to eq(200)

      find(".govuk-table").find("tr", text: "Major Update Case").find("a", text: "View").click

      expect(page.status_code).to eq(200)
      expect(page).to have_content("Major Update Case")
      expect(page).to have_content("You are about to publish a major edit with a public change note.")
      expect(page).to have_content("Publishing will email subscribers to CMA Cases.")

      expect(publish_alert_message).to eq("Publishing will email subscribers to CMA Cases. Continue?")
    end

    scenario "adds a change note" do
      visit "/cma-cases"

      expect(page.status_code).to eq(200)

      find(".govuk-table").find("tr", text: "Major Update Case").find("a", text: "View").click
      expect(page.status_code).to eq(200)

      click_link "Edit document"

      fill_in "Title", with: "Changed title"
      choose "Major"
      fill_in "Change note", with: "Updated change note"

      click_button "Save as draft"

      assert_publishing_api_put_content(
        content_id,
        lambda { |request|
          payload = JSON.parse(request.body)

          expect(payload["title"]).to eq("Changed title")
          expect(payload["update_type"]).to eq("major")
          expect(payload["change_note"]).to eq("Updated change note")
        },
      )
    end
  end

  context "when there is a redrafted document with a minor update" do
    let(:item) do
      FactoryBot.create(
        :cma_case,
        :redrafted,
        title: "Minor Update Case",
        update_type: "minor",
      )
    end

    scenario "alerts should not be sent when the item is published" do
      visit "/cma-cases"

      expect(page.status_code).to eq(200)

      find(".govuk-table").find("tr", text: "Minor Update Case").find("a", text: "View").click

      expect(page.status_code).to eq(200)
      expect(page).to have_content("Minor Update Case")

      click_button "Publish"
      expect(page.status_code).to eq(200)
      expect(page).to have_content("Published Minor Update Case")

      assert_publishing_api_publish(content_id)

      assert_not_requested(:post, "#{Plek.find('email-alert-api')}/notifications")
    end

    scenario "publish warning and popup text will indicate that it is a minor edit" do
      visit "/cma-cases"

      expect(page.status_code).to eq(200)

      find(".govuk-table").find("tr", text: "Minor Update Case").find("a", text: "View").click

      expect(page.status_code).to eq(200)
      expect(page).to have_content("Minor Update Case")
      expect(page).to have_content("You are about to publish a minor edit.")
      expect(page).to have_no_content("Publishing will email subscribers to CMA Cases.")

      expect(publish_alert_message).to eq("You are about to publish a minor edit. Continue?")
    end
  end

  context "when the document is unpublished" do
    let(:item) do
      FactoryBot.create(
        :cma_case,
        :published,
        title: "Unpublished Item",
        publication_state: "unpublished",
      )
    end

    scenario "when content item is unpublished it cannot be published" do
      visit "/cma-cases"
      expect(page.status_code).to eq(200)

      find(".govuk-table").find("tr", text: "Unpublished Item").find("a", text: "View").click

      expect(page).to have_no_selector(:button, "Publish")
      expect(page).to have_content("The document is unpublished. You need to create a new draft before it can be published.")
    end
  end
end
