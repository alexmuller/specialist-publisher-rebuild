source "https://rubygems.org"

gem "rails", "8.0.1"

gem "aws-sdk-s3"
gem "bootsnap", require: false
gem "bootstrap-kaminari-views"
gem "dartsass-rails"
gem "diffy"
gem "gds-api-adapters"
gem "gds-sso"
gem "govspeak"
gem "govuk_admin_template"
gem "govuk_app_config"
gem "govuk_frontend_toolkit"
gem "govuk_publishing_components"
gem "govuk_sidekiq"
gem "hashdiff"
gem "jquery-rails"
gem "kaminari"
gem "kaminari-mongoid"
gem "mail-notify"
gem "mongo"
gem "mongoid"
gem "multi_json"
gem "plek"
gem "pundit"
# TODO: remove after next version of Puma is released
# See https://github.com/puma/puma/pull/3532
# `require: false` is needed because you can't actually `require "rackup"`
# due to a different bug: https://github.com/rack/rackup/commit/d03e1789
gem "rackup", "1.0.0", require: false
gem "select2-rails", "< 4" # v4 changes the generated HTML and breaks the e2e tests
gem "sentry-sidekiq"
gem "stringex"
gem "terser"
gem "view_component"

group :development do
  gem "listen"
end

group :development, :test do
  gem "better_errors"
  gem "binding_of_caller"
  gem "capybara-select-2"
  gem "database_cleaner-mongoid"
  gem "factory_bot"
  gem "govuk_schemas"
  gem "govuk_test"
  gem "pry-rails"
  gem "puma"
  gem "rspec-rails"
  gem "rubocop-govuk", require: false
  gem "simplecov", require: false
  gem "timecop"
end

group :test do
  gem "rails-controller-testing"
  gem "webmock"
end
