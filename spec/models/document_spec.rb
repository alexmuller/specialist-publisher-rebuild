require "spec_helper"

RSpec.describe Document do
  let(:document_sub_class) do
    Class.new(Document) do
      def self.title
        "My Document Type"
      end

      def self.document_type
        "my_document_type"
      end

      attr_accessor :field1, :field2, :field3

      def initialize(params = {})
        super(params, %i[field1 field2 field3])
      end

      apply_validations
    end
  end
  let(:finder_schema) do
    schema = FinderSchema.new
    schema.assign_attributes({
      base_path: "/my-document-types",
      target_stack: "live",
      filter: {
        "format" => "my_format",
      },
      content_id: @finder_content_id,
    })
    schema
  end
  let(:payload_attributes) do
    {
      document_type: "my_document_type",
      title: "Example document",
      description: "This is a summary",
      base_path: "/my-document-types/example-document",
      details: {
        body: [
          {
            content_type: "text/govspeak",
            content: "This is the body of an example document",
          },
        ],
        metadata: {
          field1: "2015-12-01",
          field2: "open",
          field3: %w[x y z],
        },
      },
      links: {
        finder: [@finder_content_id],
      },
    }
  end
  let(:payload) { FactoryBot.create(:document, payload_attributes) }
  let(:document) { MyDocumentType.from_publishing_api(payload) }

  before do
    allow(FinderSchema).to receive(:load_from_schema).with("my_document_types").and_return(finder_schema)
    stub_const("MyDocumentType", document_sub_class)
  end

  before(:all) do
    # this value is cached in the Document as a class variable, so we need it
    # to not change between tests
    @finder_content_id = SecureRandom.uuid
  end

  it "has a document_type for building URLs" do
    expect(MyDocumentType.admin_slug).to eq("my-document-types")
  end

  it "has a document_type for fetching params of the format" do
    expect(MyDocumentType.document_type).to eq("my_document_type")
  end

  it "has a link to the live URL of the finder" do
    schema = double("some schema", base_path: "/foo")
    allow(MyDocumentType).to receive(:finder_schema).and_return(schema)
    expect(MyDocumentType.live_url).to eq("http://www.dev.gov.uk/foo")
  end

  it "has a link to the draft URL of the finder" do
    schema = double("some schema", base_path: "/foo")
    allow(MyDocumentType).to receive(:finder_schema).and_return(schema)
    expect(MyDocumentType.draft_url).to eq("http://draft-origin.dev.gov.uk/foo")
  end

  describe "parsing date params" do
    it "sets a date string from rails date select style params" do
      doc = MyDocumentType.new("field1(1i)": "2016", "field1(2i)": "09", "field1(3i)": "07")
      expect(doc.field1).to eq("2016-09-07")
    end

    it "formats the date consistently" do
      doc = MyDocumentType.new("field1(1i)": "2016", "field1(2i)": "9", "field1(3i)": "07")
      expect(doc.field1).to eq("2016-09-07")
    end
  end

  describe ".all" do
    it "makes a request to the publishing api with the correct params" do
      publishing_api = double(:publishing_api)
      allow(Services).to receive(:publishing_api).and_return(publishing_api)

      expect(publishing_api).to receive(:get_content_items)
        .with(
          {
            publishing_app: "specialist-publisher",
            document_type: "my_document_type",
            fields: %i[
              base_path
              content_id
              locale
              last_edited_at
              title
              publication_state
              state_history
            ],
            page: 1,
            per_page: 20,
            locale: "all",
            order: "-last_edited_at",
            q: "foo",
          },
        )

      MyDocumentType.all(1, 20, query: "foo")
    end
  end

  context "saving a new draft" do
    subject { MyDocumentType.new }

    before do
      stub_any_publishing_api_put_content
      stub_any_publishing_api_patch_links
      subject.title = "Title"
      subject.summary = "Summary"
      subject.body = "Body"
      subject.publication_state = nil
    end

    it "sends a correct document" do
      allow(FinderSchema).to receive(:load_from_schema).with("my_document_types")
        .and_return(finder_schema)

      expect(subject.save).to be true
      assert_publishing_api_put_content(subject.content_id, request_json_includes(update_type: "major"))
    end

    describe "#summary" do
      before { subject.summary = nil }

      context "when document_type is not 'protected_food_drink_name'" do
        it "requires a summary" do
          expect(subject).to_not be_valid
          expect(subject.errors.messages).to eq(summary: ["can't be blank"])
        end
      end

      context "when document_type is 'protected_food_drink_name'" do
        before { expect(subject).to receive(:document_type).and_return("protected_food_drink_name") }

        it "does not require a summary" do
          expect(subject).to be_valid
          expect(subject.errors.messages).to be_blank
        end
      end
    end
  end

  describe ".from_publishing_api" do
    context "for a published document" do
      let(:payload) { FactoryBot.create(:document, :published, payload_attributes) }

      it "sets the top-level attributes on a document" do
        expect(document.base_path).to eq(payload["base_path"])
        expect(document.content_id).to eq(payload["content_id"])
        expect(document.title).to eq(payload["title"])
        expect(document.summary).to eq(payload["description"])
        expect(document.publication_state).to eq(payload["publication_state"])
        expect(document.public_updated_at).to eq(payload["public_updated_at"])
        expect(document.first_published_at).to eq(payload["first_published_at"])
        expect(document.update_type).to eq(nil)
        expect(document.state_history).to eq(payload["state_history"])
        expect(document.rendering_app).to eq("government-frontend")
      end

      context "when bulk published is true" do
        let(:payload_attributes) do
          {
            details: {
              metadata: {
                bulk_published: true,
              },
            },
          }
        end

        specify { expect(document.bulk_published).to eq(true) }
      end

      context "when bulk published is not present in metadata" do
        let(:payload_attributes) do
          {
            details: {
              metadata: {},
            },
          }
        end

        specify { expect(document.bulk_published).to eq(false) }
      end

      context "when the body contains multiple content types" do
        let(:payload_attributes) do
          {
            details: {
              body: [
                { content_type: "text/govspeak", content: "# hello" },
                { content_type: "text/html", content: "<h1>hello</h1>" },
              ],
            },
          }
        end

        it "sets the body to the content of the govspeak type" do
          expect(document.body).to eq("# hello")
        end
      end

      context "when the body is just a string" do
        let(:payload_attributes) do
          {
            details: {
              body: "This is just a string.",
            },
          }
        end

        it "sets the body to that string" do
          expect(document.body).to eq("This is just a string.")
        end
      end

      it "sets its attachments collection from the payload" do
        expect(document.attachments).to be_an(AttachmentCollection)
      end

      it "sets format specific fields for the document subclass" do
        expect(document.format_specific_fields).to eq(%i[field1 field2 field3])

        expect(document.field1).to eq("2015-12-01")
        expect(document.field2).to eq("open")
        expect(document.field3).to eq(%w[x y z])
      end
    end

    context "when the document is redrafted" do
      let(:payload) do
        FactoryBot.create(
          :document,
          :redrafted,
          payload_attributes.merge(update_type: "minor"),
        )
      end
      it "sets the update type" do
        expect(document.update_type).to eq(payload["update_type"])
      end
    end

    context "when the document has a temporary update type" do
      let(:payload_attributes) { { details: { temporary_update_type: true } } }

      it "sets update type to nil and clears the temporary update type" do
        expect(document.update_type).to be_nil
        expect(document.temporary_update_type).to eq(false)
      end
    end
  end

  context "successful #publish" do
    let(:payload) { FactoryBot.create(:document, :published, payload_attributes) }
    before do
      stub_any_publishing_api_put_content
      stub_any_publishing_api_patch_links
      stub_publishing_api_publish(document.content_id, {})
      stub_publishing_api_has_item(payload)
      @email_alert_api = stub_email_alert_api_accepts_content_change
    end

    it "sends a payload to Publishing API" do
      expect(document.publish).to eq(true)

      assert_publishing_api_publish(document.content_id)
    end

    it "alerts the email API for major updates" do
      document.update_type = "major"

      expect(document.publish).to eq(true)

      assert_email_alert_api_content_change_created(
        "tags" => {
          "format" => "my_format",
          "field1" => "2015-12-01",
          "field2" => "open",
          "field3" => %w[x y z],
        },
        "document_type" => "my_document_type",
      )
    end

    context "document is redrafted with a minor edit" do
      let(:minor_change_document) do
        MyDocumentType.from_publishing_api(
          FactoryBot.create(
            :document,
            payload_attributes.merge(
              publication_state: "published",
              update_type: "minor",
              content_id: document.content_id,
            ),
          ),
        )
      end

      it "doesn't alert the email API for minor updates" do
        expect(minor_change_document.publish).to eq(true)

        expect(@email_alert_api).to_not have_been_requested
      end
    end

    context "document has never been published" do
      let(:unpublished_document) do
        MyDocumentType.from_publishing_api(
          FactoryBot.create(
            :document,
            payload_attributes.merge(
              first_published_at: nil,
              publication_state: "draft",
              content_id: document.content_id,
            ),
          ),
        )
      end

      it 'saves a "First published." change note before asking the api to publish' do
        Timecop.freeze(Time.zone.parse("2015-12-18 10:12:26 UTC")) do
          unpublished_document.publish

          changed_json = {
            update_type: "major",
            change_note: "First published.",
          }

          assert_publishing_api_put_content(unpublished_document.content_id, request_json_includes(changed_json))
        end
      end

      context "when the document has previously been unpublished" do
        before do
          document.state_history = { "1" => "unpublished", "2" => "draft" }
        end

        it "asynchronously restores attachments" do
          expect(AttachmentRestoreWorker).to receive(:perform_async)
            .with(document.content_id, document.locale)

          document.publish
        end
      end
    end

    shared_examples_for "publishing changes to a document that has previously been published" do
      let(:published_document) do
        MyDocumentType.from_publishing_api(
          FactoryBot.create(
            :document,
            :redrafted,
            payload_attributes.merge(
              publication_state:,
              content_id: document.content_id,
            ),
          ),
        )
      end

      it 'does not add a "First published" change note before asking the api to publish' do
        published_document.publish

        assert_no_publishing_api_put_content(published_document.content_id)
      end
    end

    context "when document is in live state" do
      let(:publication_state) { "published" }
      it_behaves_like "publishing changes to a document that has previously been published"
    end

    context "when document is in redrafted state" do
      let(:publication_state) { "draft" }
      it_behaves_like "publishing changes to a document that has previously been published"
    end

    context "when document is in unpublished state" do
      let(:publication_state) { "unpublished" }
      it_behaves_like "publishing changes to a document that has previously been published"
    end

    context "when document is in superseded state" do
      let(:publication_state) { "superseded" }
      it_behaves_like "publishing changes to a document that has previously been published"
    end
  end

  context "unsuccessful #publish" do
    let(:payload) { FactoryBot.create(:document, :published, payload_attributes) }

    it "notifies GovukError and returns false if publishing-api does not return status 200" do
      expect(GovukError).to receive(:notify)
      stub_any_publishing_api_put_content
      stub_any_publishing_api_patch_links
      stub_publishing_api_publish(document.content_id, {}, status: 503)
      expect(document.publish).to eq(false)
    end
  end

  describe "#unpublish" do
    before do
      stub_publishing_api_has_item(payload)
      document = MyDocumentType.find(payload["content_id"], payload["locale"])
      stub_publishing_api_unpublish(document.content_id, body: { locale: document.locale, type: "gone" })
    end

    it "sends correct payload to publishing api" do
      expect(document.unpublish).to eq(true)

      assert_publishing_api_unpublish(document.content_id, type: "gone", locale: document.locale)
    end

    it "deletes document attachments" do
      expect(AttachmentDeleteWorker).to receive(:perform_async).with(payload["content_id"], payload["locale"])

      document.unpublish
    end

    context "with an alternative path" do
      it "sends correct payload to publishing api" do
        stub_publishing_api_has_lookups("/foo" => SecureRandom.uuid)
        stub_publishing_api_unpublish(document.content_id, body: { type: "redirect", locale: document.locale, alternative_path: "/foo" })

        expect(document.unpublish("/foo")).to eq(true)

        assert_publishing_api_unpublish(document.content_id, type: "redirect", locale: document.locale, alternative_path: "/foo")
      end
    end

    context "unsuccessful #unpublish" do
      it "notifies GovukError and returns false if publishing-api does not return status 200" do
        expect(GovukError).to receive(:notify)
        stub_publishing_api_unpublish(document.content_id, { body: { type: "gone", locale: document.locale } }, status: 409)
        expect(document.unpublish).to eq(false)
      end
    end
  end

  describe "#discard" do
    let(:content_id) { payload.fetch("content_id") }

    it "sends a discard draft request to the publishing api" do
      stub_publishing_api_discard_draft(content_id)
      document.discard
      assert_publishing_api_discard_draft(content_id)
    end

    it "returns true if the draft was discarded successfully" do
      stub_publishing_api_discard_draft(content_id)
      expect(document.discard).to eq(true)
    end

    it "returns false if the draft could not be discarded" do
      stub_request(:any, /discard/).to_raise(GdsApi::HTTPErrorResponse)
      expect(document.discard).to eq(false)
    end
  end

  describe "#save" do
    before do
      stub_publishing_api_has_item(payload)
      Timecop.freeze(Time.zone.parse("2015-12-18 10:12:26 UTC"))
    end

    it "saves document" do
      stub_any_publishing_api_put_content
      stub_any_publishing_api_patch_links

      c = MyDocumentType.find(payload["content_id"], payload["locale"])
      expect(c.save).to eq(true)

      expected_payload = write_payload(payload.deep_stringify_keys)
      assert_publishing_api_put_content(c.content_id, expected_payload)
    end

    it "returns false without making any Publishing API calls if the document is invalid" do
      stub = stub_any_publishing_api_call

      document.title = nil # this is an invalid title
      expect(document).to_not be_valid

      expect(document.save).to be_falsey
      expect(stub).to_not have_been_requested
    end

    it "returns false if the Publishing API calls fail" do
      stub_publishing_api_isnt_available
      expect(document.save).to be_falsey
    end

    describe "validations" do
      subject { Document.from_publishing_api(payload) }

      context "when the document is a draft" do
        let(:payload) { FactoryBot.create(:document) }

        it "does not require an update_type" do
          subject.update_type = ""
          expect(subject).to be_valid
        end

        it "does not require a change_note" do
          subject.change_note = ""
          expect(subject).to be_valid
        end
      end

      context "when the document is published" do
        let(:payload) do
          FactoryBot.create(:document, :published, state_history: { "1" => "published" })
        end

        it "requires an update_type" do
          subject.update_type = ""
          subject.change_note = "change note"

          expect(subject).not_to be_valid
        end

        it "requires a change_note" do
          subject.update_type = "major"
          subject.change_note = ""

          expect(subject).not_to be_valid
        end
      end

      context "when the document is unpublished" do
        let(:payload) do
          FactoryBot.create(:document, :unpublished, state_history: { "1" => "published", "2" => "unpublished" })
        end

        it "requires an update_type" do
          subject.update_type = ""
          subject.change_note = "change note"

          expect(subject).not_to be_valid
        end

        it "requires a change_note" do
          subject.update_type = "major"
          subject.change_note = ""

          expect(subject).not_to be_valid
        end
      end

      context "when the document is brand new" do
        subject { Document.new }

        before do
          subject.title = "Title"
          subject.summary = "Summary"
          subject.body = "Body"
        end

        it "does not require an update_type" do
          subject.update_type = ""
          expect(subject).to be_valid
        end

        it "does not require a change_note" do
          subject.change_note = ""
          expect(subject).to be_valid
        end
      end
    end
  end

  describe ".find" do
    before do
      stub_publishing_api_has_item(payload)
    end

    it "returns a document" do
      found_document = MyDocumentType.find(document.content_id, document.locale)

      expect(found_document.base_path).to eq(payload["base_path"])
      expect(found_document.title).to     eq(payload["title"])
      expect(found_document.summary).to   eq(payload["description"])
      expect(found_document.body).to      eq(payload["details"]["body"][0]["content"])
      expect(found_document.field3).to    eq(payload["details"]["metadata"]["field3"])
    end

    describe "when called on the Document superclass" do
      it "returns an instance of the subclass with matching document_type" do
        found_document = Document.find(document.content_id, document.locale)
        expect(found_document).to be_a(MyDocumentType)
      end
    end

    describe "when called on a class that mismatches the document_type" do
      it "raises a helpful error" do
        expect {
          CmaCase.find(document.content_id, document.locale)
        }.to raise_error(/wrong type/)
      end
    end
  end

  describe "attachment methods" do
    let(:attachment) { Attachment.new }

    describe "#attachments=" do
      it "creates an AttachmentCollection with the given attachments" do
        subject.attachments = [attachment]

        expect(subject.attachments).to be_kind_of(AttachmentCollection)
        expect(subject.attachments.first).to eq(attachment)
      end
    end

    describe "#attachments" do
      it "returns an empty AttachmentCollection if none is set" do
        expect(subject.attachments).to be_kind_of(AttachmentCollection)
        expect(subject.attachments.count).to eq(0)
      end
    end

    describe "#upload_attachment" do
      before do
        subject.attachments = [attachment]
      end

      it "saves itself on successful attachment upload" do
        expect(subject.attachments).to receive(:upload).and_return(true)
        expect(subject).to receive(:save)
        subject.upload_attachment(attachment)
      end

      it "returns false on failed attachment upload" do
        expect(subject.attachments).to receive(:upload).and_return(false)

        expect(subject.upload_attachment(attachment)).to eq(false)
      end
    end

    describe "#delete_attachment" do
      before do
        subject.attachments = [attachment]
      end

      it "deletes its attachment on a successful API call" do
        expect(subject.attachments).to receive(:remove).and_return(true)
        expect(subject).to receive(:save)
        subject.delete_attachment(attachment)
        expect subject.attachments.count == 0
      end

      it "returns false and preserves its attachment on a failed call" do
        expect(subject.attachments).to receive(:remove).and_return(false)
        expect(subject.delete_attachment(attachment)).to eq(false)
        expect subject.attachments.count == 1
      end
    end
  end

  describe "#set_temporary_update_type!" do
    before { subject.publication_state = "published" }

    context "when the document has an update_type" do
      before do
        subject.update_type = "major"
        subject.set_temporary_update_type!
      end

      it "preserves the existing attributes" do
        expect(subject.update_type).to eq("major")
        expect(subject.temporary_update_type).to be_falsey
      end
    end

    context "when the document does not have an update_type" do
      before do
        subject.update_type = nil
        subject.set_temporary_update_type!
      end

      it "sets update_type to minor and temporary_update_type to true" do
        expect(subject.update_type).to eq("minor")
        expect(subject.temporary_update_type).to eq(true)
      end
    end
  end

  context "change_note" do
    subject { MyDocumentType.new }

    it "sets the change note when it is a major update" do
      subject.update_type = "major"
      subject.change_note = "some change note"

      expect(subject.change_note).to eq("some change note")
    end

    it "does not set the change note when it is a minor update" do
      subject.update_type = "minor"
      subject.change_note = "some change note"

      expect(subject.change_note).to be_nil
    end

    it "does not the change note when the update_type is not set" do
      subject.update_type = nil
      subject.change_note = "some change note"

      expect(subject.change_note).to be_nil
    end
  end

  context "#first_draft?" do
    subject { MyDocumentType.new }
    it "is true if the state_history is less than 2" do
      subject.state_history = nil
      expect(subject.first_draft?).to eq(true)
    end

    it "is true if the state_history indicates it has not been published" do
      subject.state_history = { "1" => "draft" }
      expect(subject.first_draft?).to eq(true)
    end

    it "is false if the state_history indicates it has been published" do
      subject.state_history = { "3" => "draft", "2" => "published", "1" => "superseded" }
      expect(subject.first_draft?).to eq(false)
    end

    it "is true if there is a first_published_at and a state history indicating it has not been published" do
      subject.state_history = { "1" => "draft" }
      subject.first_published_at = "2019-02-21T00:00:00+00:00"
      expect(subject.first_draft?).to eq(true)
    end
  end

  context "saving a draft where another draft has the same base_path" do
    before do
      stub_any_publishing_api_put_content
        .to_raise(GdsApi::HTTPErrorResponse.new(422, "base path=/foo/bar conflicts with content_id=123"))
    end

    subject do
      MyDocumentType.new(
        title: "A document",
        summary: "An introduction",
        body: "Some text",
      )
    end

    it "cannot be saved" do
      expect(subject.save).to be false
    end

    it "populates an error on the document" do
      subject.save
      expect(subject.errors[:base]).to eq(["Warning: This document's URL is already used on GOV.UK. You can't publish it until you change the title."])
    end
  end

  context "a draft where a published item has the same base_path" do
    let(:content_id) { SecureRandom.uuid }
    let(:locale) { "en" }
    let(:published) { FactoryBot.create(:document, document_type: "my_document_type", content_id:) }

    before do
      stub_request(:get, %r{/v2/content/#{content_id}})
        .to_return(status: 200,
                   body: published.merge(warnings: { "content_item_blocking_publish" => "foo" }).to_json)
    end

    subject { described_class.find(content_id, locale) }

    it "cannot be published" do
      expect(subject.publish).to be false
    end

    it "populates warnings on the document" do
      expect(subject.warnings).to eq("content_item_blocking_publish" => "foo")
    end

    it "can be saved" do
      stub_any_publishing_api_put_content
      stub_any_publishing_api_patch_links
      subject.update_type = "minor"
      expect(subject.save).to be true
    end
  end

  describe "#taxons" do
    it "delegates to the FinderSchema" do
      document = MyDocumentType.new
      allow(document.finder_schema).to receive(:taxons).and_return(%w[foo])
      expect(document.taxons).to eq(%w[foo])
    end
  end

  describe "#target_stack" do
    it "delegates to the FinderSchema" do
      allow(MyDocumentType.finder_schema).to receive(:target_stack).and_return("draft")
      expect(MyDocumentType.target_stack).to eq("draft")
    end
  end

  describe "#primary_publishing_organisation" do
    it "returns the first organisation from the FinderSchema" do
      document = MyDocumentType.new
      allow(document.finder_schema).to receive(:organisations).and_return(%w[foo bar])
      expect(document.primary_publishing_organisation).to eq("foo")
    end
  end

  describe ".title" do
    it "delegates to the FinderSchema" do
      allow(FinderSchema).to receive(:load_from_schema).and_return(finder_schema)
      expect(AaibReport.finder_schema).to receive(:document_title).and_return("AAIB Report")
      expect(AaibReport.title).to eq("AAIB Report")
    end
  end

  describe "#send_email_on_publish?" do
    it "should send email if document is major update and no disable_email_alert override exists" do
      doc = MyDocumentType.new(update_type: "major")
      expect(doc.send_email_on_publish?).to be true
    end

    it "should send email if document is major update and disable_email_alert override is false" do
      doc = MyDocumentType.new(update_type: "major")
      doc.disable_email_alert = false
      expect(doc.send_email_on_publish?).to be true
    end

    it "should raise an error if document is major update and disable_email_alert override is a random string" do
      doc = MyDocumentType.new(update_type: "major")
      doc.disable_email_alert = "invalid"
      expect { doc.send_email_on_publish? }.to raise_error("Invalid disable email alert flag. Please use booleans only.")
    end

    it "should stop send email if document is major update and disable_email_alert override is true" do
      doc = MyDocumentType.new(update_type: "major")
      doc.disable_email_alert = true
      expect(doc.send_email_on_publish?).to be false
    end

    it "should stop send email if document is minor update and disable_email_alert override is true" do
      doc = MyDocumentType.new(update_type: "minor")
      doc.disable_email_alert = true
      expect(doc.send_email_on_publish?).to be false
    end

    it "should stop send email if document is minor update even if disable_email_alert override is false" do
      doc = MyDocumentType.new(update_type: "minor")
      doc.disable_email_alert = false
      expect(doc.send_email_on_publish?).to be false
    end
  end

  describe ".apply_validations" do
    context "required" do
      let(:finder_schema) do
        schema = FinderSchema.new
        schema.assign_attributes({
          base_path: "/my-document-types",
          target_stack: "live",
          filter: {
            "format" => "my_format",
          },
          content_id: @finder_content_id,
          facets: [
            {
              "key" => "field1",
              "name" => "field1 name",
              "type" => "text",
              "specialist_publisher_properties" => {
                "validations" => {
                  "required" => {},
                },
              },
            },
            {
              "key" => "field2",
              "name" => "field2 name",
              "type" => "text",
              "specialist_publisher_properties" => {
                "validations" => {
                  "required" => { "message" => "can't be empty - custom" },
                },
              },
            },
          ],
        })
        schema
      end

      let(:payload_attributes) do
        {
          document_type: "my_document_type",
          title: "Example document",
          description: "This is a summary",
          base_path: "/my-document-types/example-document",
          details: {
            body: [
              {
                content_type: "text/govspeak",
                content: "This is the body of an example document",
              },
            ],
            metadata: {
              field1: "",
              field2: nil,
            },
          },
          links: {
            finder: [@finder_content_id],
          },
        }
      end

      it "is invalid without required field" do
        expect(document).to be_invalid
        expect(document.errors[:field1]).to eq(["can't be blank"])
        expect(document.errors[:field2]).to eq(["can't be empty - custom"])
      end
    end
  end
end
