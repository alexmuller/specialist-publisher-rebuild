class FinderAdministrationPolicy
  attr_reader :user

  # TODO: figure out why the exact same user object is passed in as
  # two params from the controller. I must be doing something wrong,
  # even if it's basically harmless!
  def initialize(user, _user)
    @user = user
  end

  delegate :gds_editor?, to: :user

  def can_request_new_finder?
    gds_editor?
  end
end
