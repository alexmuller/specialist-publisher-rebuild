require "spec_helper"

RSpec.describe "EmailAlert" do
  describe "#from_finder_schema" do
    it "builds an email alert for a finder schema with alerts configured for all content" do
      schema = FinderSchema.new
      schema.signup_content_id = "123"
      schema.subscription_list_title_prefix = "Finder email subscription"
      email_alert = EmailAlert.from_finder_schema(schema)
      expect(email_alert.type).to eq(:all_content)
      expect(email_alert.content_id).to eq(schema.signup_content_id)
      expect(email_alert.list_title_prefix).to eq(schema.subscription_list_title_prefix)
    end

    it "builds an email alert for a finder schema with alerts configured for a filtered set of the content" do
      schema = FinderSchema.new
      schema.signup_content_id = "123"
      schema.email_filter_options = { "email_filter_by" => "some_facet" }
      schema.subscription_list_title_prefix = "Finder email subscription"
      email_alert = EmailAlert.from_finder_schema(schema)
      expect(email_alert.type).to eq(:filtered_content)
      expect(email_alert.content_id).to eq(schema.signup_content_id)
      expect(email_alert.list_title_prefix).to eq(schema.subscription_list_title_prefix)
      expect(email_alert.filter).to eq("some_facet")
    end

    it "builds an email alert for a finder schema with alerts configured to use an external system" do
      schema = FinderSchema.new
      schema.signup_link = "https://example.com"
      email_alert = EmailAlert.from_finder_schema(schema)
      expect(email_alert.type).to eq(:external)
      expect(email_alert.link).to eq(schema.signup_link)
    end

    it "builds an email alert for a finder schema without alerts configured" do
      schema = FinderSchema.new
      email_alert = EmailAlert.from_finder_schema(schema)
      expect(email_alert.type).to eq(:no)
    end
  end

  describe "#from_finder_admin_form_params" do
    it "builds an email alert for a finder schema with alerts configured for all content" do
      params = {
        "email_alert_type" => "all_content",
        "all_content_signup_id" => "123",
        "all_content_list_title_prefix" => "Finder email subscription",
      }
      email_alert = EmailAlert.from_finder_admin_form_params(params)
      expect(email_alert.type).to eq(:all_content)
      expect(email_alert.content_id).to eq(params["all_content_signup_id"])
      expect(email_alert.list_title_prefix).to eq(params["all_content_list_title_prefix"])
    end

    it "builds an email alert for a finder schema with alerts configured for a filtered set of the content" do
      params = {
        "email_alert_type" => "filtered_content",
        "filtered_content_signup_id" => "123",
        "email_filter_by" => "some_facet",
        "filtered_content_list_title_prefix" => "Finder email subscription",
      }
      email_alert = EmailAlert.from_finder_admin_form_params(params)
      expect(email_alert.type).to eq(:filtered_content)
      expect(email_alert.content_id).to eq(params["filtered_content_signup_id"])
      expect(email_alert.list_title_prefix).to eq(params["filtered_content_list_title_prefix"])
      expect(email_alert.filter).to eq(params["email_filter_by"])
    end

    it "builds an email alert for a finder schema with alerts configured to use an external system" do
      params = {
        "email_alert_type" => "external",
        "signup_link" => "https://example.com",
      }
      email_alert = EmailAlert.from_finder_admin_form_params(params)
      expect(email_alert.type).to eq(:external)
      expect(email_alert.link).to eq(params["signup_link"])
    end

    it "builds an email alert for a finder schema without alerts configured" do
      params = {
        "email_alert_type" => "no",
      }
      email_alert = EmailAlert.from_finder_admin_form_params(params)
      expect(email_alert.type).to eq(:no)
    end
  end

  describe "#to_finder_schema_attributes" do
    it "transforms the attributes of the email alert to a hash of finder schema attributes" do
      email_alert = EmailAlert.new
      email_alert.content_id = "123"
      email_alert.list_title_prefix = "Finder email subscription"
      email_alert.filter = "some_facet"
      email_alert.link = "https://example.com"
      expect(email_alert.to_finder_schema_attributes).to eq({
        signup_content_id: "123",
        subscription_list_title_prefix: "Finder email subscription",
        email_filter_options: {
          email_filter_by: "some_facet",
        },
        signup_link: "https://example.com",
      })
    end
  end
end
