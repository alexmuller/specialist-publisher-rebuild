require 'spec_helper'
require_relative "../../../app/presenters/finders/finder_signup_content_item_presenter"

RSpec.describe FinderSignupContentItemPresenter do
  describe "#to_json" do
    Dir["lib/documents/schemas/*.yml"].each do |file|
      it "is valid against the #{file} content schemas" do
        payload = YAML.load_file(file)
        if payload.has_key?("signup_content_id")
          finder_signup_content_presenter = FinderSignupContentItemPresenter.new(payload, File.mtime(file))
          presented_data = finder_signup_content_presenter.to_json

          expect(presented_data[:schema_name]).to eq("finder_email_signup")
          expect(presented_data).to be_valid_against_schema("finder_email_signup")
        end
      end
    end
  end
end
