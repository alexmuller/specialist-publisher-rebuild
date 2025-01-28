class DocumentPolicy < ApplicationPolicy
  def index?
    document_type_editor? || gds_editor? || departmental_editor? || writer?
  end

  alias_method :new?, :index?
  alias_method :create?, :index?
  alias_method :edit?, :index?
  alias_method :update?, :index?
  alias_method :show?, :index?
  alias_method :destroy?, :index? # used only by AttachmentsController

  # TODO: move these into the FinderAdministrationPolicy and add associated tests
  def can_request_edits_to_finder?
    publish?
  end
  alias_method :summary?, :can_request_edits_to_finder?
  alias_method :edit_facets?, :can_request_edits_to_finder?
  alias_method :confirm_facets?, :can_request_edits_to_finder?
  alias_method :edit_metadata?, :can_request_edits_to_finder?
  alias_method :confirm_metadata?, :can_request_edits_to_finder?
  alias_method :zendesk?, :can_request_edits_to_finder?

  def publish?
    document_type_editor? || gds_editor? || departmental_editor?
  end

  alias_method :unpublish?, :publish?
  alias_method :discard?, :publish?
end
