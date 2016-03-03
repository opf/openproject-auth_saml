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

      config.after_initialize do
        # Automatically update the openproject user whenever their info change in the upstream identity provider
        OpenProject::OmniAuth::Authorization.after_login do |user, auth_hash, _context|
          # see https://github.com/opf/openproject/blob/dev/app/controllers/concerns/omniauth_login.rb#L148
          user.update_attributes _context.send(:omniauth_hash_to_user_attributes, auth_hash)
        end
      end

      register_auth_providers do
        settings = Rails.root.join('config', 'plugins', 'auth_saml', 'settings.yml')
        if settings.exist?
          providers = YAML::load(File.open(settings)).symbolize_keys
          strategy :saml do
            providers.values.map do |h|
              h[:openproject_attribute_map] = Proc.new { |auth| { login: auth[:uid], admin: (auth.info['admin'].to_s.downcase == "true") } }
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
