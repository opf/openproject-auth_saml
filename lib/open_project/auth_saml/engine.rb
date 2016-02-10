require 'omniauth-saml'
module OpenProject
  module AuthSaml
    class Engine < ::Rails::Engine
      engine_name :openproject_auth_saml

      include OpenProject::Plugins::ActsAsOpEngine
      extend OpenProject::Plugins::AuthPlugin

      register 'openproject-auth_saml',
               author_url: 'https://github.com/finnlabs/openproject-auth_saml',
               requires_openproject: '>= 5.0.0'

      assets %w(
        auth_saml/**
      )

      register_auth_providers do
        settings = Rails.root.join('config', 'plugins', 'auth_saml', 'settings.yml')
        if settings.exist?
          providers = YAML::load(File.open(settings)).symbolize_keys
          strategy :saml do
            providers.values.map do |h|
              h[:openproject_attribute_map] = Proc.new { |auth| { login: auth[:uid] } }
              h.symbolize_keys
            end
          end
        else
          Rails.logger.warn("[auth_saml] Missing settings from '#{settings}', skipping omniauth registration.")
        end
      end
    end
  end
end
