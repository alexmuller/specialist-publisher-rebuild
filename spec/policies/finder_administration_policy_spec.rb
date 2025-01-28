require "spec_helper"

RSpec.describe FinderAdministrationPolicy do
  let(:gds_editor) { User.new(permissions: %w[signin gds_editor]) }
  let(:departmental_editor) { User.new(permissions: %w[signin editor], organisation_content_id: "some-org-id") }

  permissions :can_request_new_finder? do
    it "denies access to departmental editors" do
      expect(described_class).not_to permit(departmental_editor)
    end

    it "grants access to users with GDS Editor permissions" do
      expect(described_class).to permit(gds_editor)
    end
  end
end
