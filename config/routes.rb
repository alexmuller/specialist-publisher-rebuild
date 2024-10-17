require "healthcheck/s3"

Rails.application.routes.draw do
  mount GovukPublishingComponents::Engine, at: "/component-guide" if Rails.env.development?

  get "/healthcheck/live", to: proc { [200, {}, %w[OK]] }
  get "/healthcheck/ready", to: GovukHealthcheck.rack_response(
    GovukHealthcheck::SidekiqRedis,
    GovukHealthcheck::Mongoid,
    Healthcheck::S3,
  )

  post "/preview", to: "govspeak#preview"
  get "/error", to: "passthrough#error"

  resources :document_list_export_request, path: "/export/:document_type_slug", param: :export_id, only: [:show]

  get "/admin/:document_type_slug", to: "admin#summary"
  resources :documents, path: "/:document_type_slug", param: :content_id_and_locale, except: :destroy do
    collection do
      resource :export, only: %i[show create], as: :export_documents
    end
    resources :attachments, param: :attachment_content_id, except: %i[index show]

    post :unpublish, on: :member
    post :publish, on: :member
    post :discard, on: :member
  end

  root to: "passthrough#index"
end
