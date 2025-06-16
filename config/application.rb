require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"

Bundler.require(*Rails.groups)

module RegisterEarlyCareerTeachers
  class Application < Rails::Application
    config.load_defaults 8.0
    config.autoload_lib(ignore: %w[assets tasks])
    config.assets.paths << Rails.root.join('node_modules/govuk-frontend/dist/govuk/assets')
    config.exceptions_app = routes
    config.active_record.belongs_to_required_by_default = false
    config.generators.system_tests = nil
    config.action_mailer.deliver_later_queue_name = "mailers"
    config.action_mailer.preview_paths << Rails.root.join('spec/mailers/previews')
    config.generators.system_tests = nil

    config.generators do |g|
      g.helper(false)
      g.factory_bot(suffix: "factory")
      g.test_framework(:rspec,
                       fixtures: false,
                       view_specs: false,
                       controller_specs: false,
                       helper_specs: false)
    end

    # Active record encryption
    config.active_record.encryption.primary_key = ENV["ENCRYPTION_PRIMARY_KEY"]
    config.active_record.encryption.deterministic_key = ENV["ENCRYPTION_DETERMINISTIC_KEY"]
    config.active_record.encryption.key_derivation_salt = ENV["ENCRYPTION_DERIVATION_SALT"]

    # Custom config
    config.enable_fake_trs_api = ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_FAKE_TRS_API', false))
    config.enable_personas = ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_PERSONAS', false))
    config.enable_persona_avatars = ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_PERSONA_AVATARS', true))
    config.enable_migration_testing = ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_MIGRATION_TESTING', false))
    config.enable_schools_interface = ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_SCHOOLS_INTERFACE', false))
    config.enable_sentry = ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_SENTRY', false))
    config.enable_blazer = ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_BLAZER', false))
    config.enable_bulk_upload = ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_BULK_UPLOAD', false))
    config.enable_bulk_claim = ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_BULK_CLAIM', false))
    config.enable_api = ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_API', false))
    config.sentry_dsn = ENV['SENTRY_DSN']
    config.enable_request_specs_timeout = ActiveModel::Type::Boolean.new.cast(ENV.fetch('CI', false))
    config.enable_trs_teacher_refresh = ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_TRS_TEACHER_REFRESH', true))
    config.parity_check = {
      enabled: ActiveModel::Type::Boolean.new.cast(ENV.fetch('ENABLE_PARITY_CHECK', false)),
      tokens: ENV.fetch('PARITY_CHECK_KEYS', "{}"),
      ecf_url: ENV['PARITY_CHECK_ECF_URL'],
      rect_url: ENV['PARITY_CHECK_RECT_URL'],
    }

    config.dfe_sign_in_issuer = ENV.fetch('DFE_SIGN_IN_ISSUER', 'https://dev-oidc.signin.education.gov.uk')
    config.dfe_sign_in_client_id = ENV['DFE_SIGN_IN_CLIENT_ID']
    config.dfe_sign_in_secret = ENV['DFE_SIGN_IN_SECRET']
    config.dfe_sign_in_redirect_uri = ENV['DFE_SIGN_IN_REDIRECT_URI']
    config.dfe_sign_in_sign_out_redirect_uri = ENV['DFE_SIGN_IN_SIGN_OUT_REDIRECT_URI']
    config.dfe_sign_in_enabled = [config.dfe_sign_in_client_id,
                                  config.dfe_sign_in_secret,
                                  config.dfe_sign_in_redirect_uri,
                                  config.dfe_sign_in_sign_out_redirect_uri,
                                  config.dfe_sign_in_issuer].all?

    config.support_email_address = 'teacher.induction@education.gov.uk'

    config.trs_api_base_url = ENV['TRS_API_BASE_URL']
    config.trs_api_key = ENV['TRS_API_KEY']
    config.trs_api_version = ENV.fetch('TRS_API_VERSION', '20250203')

    config.after_initialize do
      ActionView::Base.default_form_builder = GOVUKDesignSystemFormBuilder::FormBuilder
    end
  end
end
