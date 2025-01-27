class AdminController < ApplicationController
  layout "design_system"

  before_action :check_authorisation, if: :document_type_slug

  def summary; end

  def edit_facets; end

  def edit_metadata; end

  def confirm_facets
    @params = facets_params
    @params["facets"] = @params["facets"].values.map { |facet_params|
      next if facet_params["_destroy"] == "1"

      Facet.from_finder_admin_form_params(facet_params)
           .to_finder_schema_attributes
    }.compact

    @proposed_schema = FinderSchema.new(@current_format.finder_schema.attributes)
    @proposed_schema.update(@params)

    render :confirm_facets
  end

  def confirm_metadata
    @params = params.permit(
      :name,
      :base_path,
      :description,
      :summary,
      :show_summaries,
      :document_noun,
      organisations: [],
      related: [],
    )

    email_alert = EmailAlert.from_finder_admin_form_params(email_alert_params)
    @params.merge!(email_alert.to_finder_schema_attributes)

    @proposed_schema = FinderSchema.new(@current_format.finder_schema.attributes)
    @proposed_schema.update(@params.to_unsafe_h)

    if params[:include_related] != "true"
      @proposed_schema.related = nil
    end

    render :confirm_metadata
  end

  def zendesk
    GdsApi.support_api.raise_support_ticket(support_payload)
    redirect_to "/admin/#{current_format.admin_slug}", notice: "Your changes have been submitted and Zendesk ticket created."
  rescue GdsApi::HTTPErrorResponse
    flash[:danger] = "There was an error submitting your request. Please try again."
    redirect_back(fallback_location: root_path)
  end

private

  def check_authorisation
    if current_format
      authorize current_format
    else
      flash[:danger] = "That format doesn't exist. If you feel you've reached this in error, please contact your main GDS contact."
      redirect_to root_path
    end
  end

  def support_payload
    {
      subject: "Specialist Finder Edit Request: #{current_format.title.pluralize}",
      tags: %w[specialist_finder_edit_request],
      priority: "normal",
      description: "Developer - raise a PR replacing this schema with the schema below: " \
        "https://github.com/alphagov/specialist-publisher/edit/main/lib/documents/schemas/#{current_format.document_type.pluralize}.json" \
        "\r\n---\r\n" \
        "```\r\n#{params[:proposed_schema]}\r\n```",
      requester: {
        name: current_user.name,
        email: current_user.email,
      },
      editorial_remark: params[:editorial_remark],
    }
  end

  def email_alert_params
    params.permit(
      :email_alert_type,
      :all_content_signup_id,
      :all_content_list_title_prefix,
      :all_content_email_filter_options,
      :filtered_content_signup_id,
      :filtered_content_list_title_prefix,
      :filtered_content_email_filter_options,
      :email_filter_by,
      :signup_link,
    )
  end

  def facets_params
    params.permit(
      facets: [
        :key,
        :name,
        :short_name,
        :type,
        :preposition,
        :display_as_result_metadata,
        :filterable,
        :allowed_values,
        :_destroy,
        { validations: [] },
      ],
    )
  end
end
