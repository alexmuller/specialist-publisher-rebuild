module StateHelper
  def classes_for_frontend(document)
    return "label label-primary" if state_for_frontend(document) =~ /draft/

    "label label-default"
  end

  def design_system_classes_for_frontend(document)
    return "govuk-tag govuk-tag--blue" if state_for_frontend(document) =~ /draft/

    "govuk-tag govuk-tag--green"
  end

  def state_for_frontend(document)
    compose_state(document.state_history.to_h)
  end

  def compose_state(state_history)
    previous_state, latest_state = last_two_states(state_history)
    if previous_state && latest_state == "draft"
      "#{previous_state} with new draft"
    else
      latest_state
    end
  end

  def ordered_history(state_history)
    ordered_history = state_history.sort_by { |k, _v| Integer(k.to_s) }
    ordered_history.map!(&:second)
  end

  def last_two_states(state_history)
    history = ordered_history(state_history)
    [history[-2], history[-1]]
  end

  def show_view_on_website_link?(state_history)
    last_two_states(state_history).include?("published")
  end

  def show_preview_draft_link?(state_history)
    ordered_history(state_history).last == "draft"
  end
end
