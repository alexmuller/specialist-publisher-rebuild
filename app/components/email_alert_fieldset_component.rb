class EmailAlertFieldsetComponent < ViewComponent::Base
  def initialize(email_alert:)
    @email_alert = email_alert
  end

  def render_all_content_condition_inputs
    hidden_signup_content_id_input = hidden_signup_content_id_input("all_content_signup_id")

    # Do not render the title prefix input if the value is a hash because we don't want to override the existing the existing
    # values in such cases. We are going to revisit this later, but for now we only allow users to override this setting
    # for finders with a single string value. Trello card for future work: https://trello.com/c/Qe8wOpaw
    return hidden_signup_content_id_input if @email_alert.list_title_prefix.is_a?(Hash)

    email_topic_list_title_prefix("all_content_list_title_prefix") + hidden_signup_content_id_input
  end

  # We are handling changes to email facet filters offline at present.
  def render_filtered_content_condition_inputs
    hidden_signup_content_id_input("filtered_content_signup_id") +
      render("govuk_publishing_components/components/checkboxes", {
        name: "email_filter_by",
        heading: "Selected filter: #{@email_alert.filter&.humanize}",
        items: [
          {
            label: "Make changes to this filter criteria (The development team will reach out to you to discuss the requirements to allow users to sign up by specific filter criteria)",
            value: "CHANGE_REQUESTED",
          },
        ],
      })
  end

  def render_external_condition_inputs
    render("govuk_publishing_components/components/input", {
      label: {
        text: "Signup link",
      },
      hint: "A link to an email signup page",
      name: "signup_link",
      value: @email_alert.link,
    })
  end

private

  def email_topic_list_title_prefix(input_name)
    render("govuk_publishing_components/components/input", {
      label: {
        text: "Email subscription topic",
      },
      name: input_name,
      value: @email_alert.list_title_prefix,
    })
  end

  def hidden_signup_content_id_input(input_name)
    render("govuk_publishing_components/components/input", {
      type: "hidden",
      name: input_name,
      value: @email_alert.content_id || SecureRandom.uuid,
    })
  end
end
