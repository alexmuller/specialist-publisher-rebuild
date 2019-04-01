source 'https://rubygems.org'

gem 'rails', '~> 5'

gem 'bootstrap-kaminari-views', '~> 0.0.5'
gem 'govuk_sidekiq', '~> 3'
gem 'govuk_test'
gem 'hashdiff'
gem 'jquery-rails', '~> 4'
gem 'kaminari'
gem 'kaminari-mongoid'
# MongoDB 2.4 compatibility is required, which was removed in 6.3
gem 'mongoid', '< 6.3'
# MongoDB 2.4 compatibility is required, which was removed in 2.5
gem 'mongo', '< 2.5'
gem 'pundit'
gem 'sass-rails', '~> 5'
gem 'select2-rails', '~> 3'
gem 'uglifier', '~> 4'

# GDS managed dependencies
gem 'gds-api-adapters', '~> 58'
gem 'gds-sso', '~> 14'
gem 'govspeak', '~> 6'
gem 'govuk_admin_template', '~> 6'
gem 'govuk_frontend_toolkit', '~> 8'
gem 'plek', '~> 2'
gem 'govuk_app_config', '~> 1'

group :development, :test do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'capybara-select-2'
  gem 'database_cleaner'
  gem 'factory_bot'
  gem 'govuk-content-schema-test-helpers'
  gem 'govuk-lint'
  gem 'pry-rails'
  gem 'puma'
  gem 'rspec-rails'
  gem 'simplecov', require: false
  gem 'timecop'
end

group :test do
  gem 'rails-controller-testing'
  gem 'webmock'
end
