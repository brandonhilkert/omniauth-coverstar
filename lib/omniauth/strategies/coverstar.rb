require "omniauth-oauth2"
require "json"
require "base64"

module OmniAuth
  module Strategies
    class Coverstar < OmniAuth::Strategies::OAuth2
      option :name, "coverstar"

      option :client_options,
        site:          "https://auth.coverstar.app",
        authorize_url: "/login",
        token_url:     "/oauth2/token"

      option :scope, "openid email profile"
      option :api_base_url, "https://api.spotlight.social/external-v1/"

      uid { decoded_id_token["sub"] }

      info do
        {
          email:       raw_info.dig("data", "email"),
          name:        raw_info.dig("data", "preferredName"),
          description: raw_info.dig("data", "description")
        }
      end

      credentials do
        hash                  = { "token" => access_token.token }
        hash["id_token"]      = access_token["id_token"] if access_token["id_token"]
        hash["refresh_token"] = access_token.refresh_token if access_token.refresh_token
        hash["expires_at"]    = access_token.expires_at if access_token.expires?
        hash["expires"]       = access_token.expires?
        hash
      end

      extra do
        { raw_info: raw_info }
      end

      def raw_info
        @raw_info ||= fetch_profile
      end

      private
        def callback_url
          options[:redirect_uri] || (full_host + script_name + callback_path)
        end

        def decoded_id_token
          @decoded_id_token ||= begin
            id_token = access_token["id_token"]
            payload = id_token.split(".")[1]
            # Add padding for Base64 decode
            padded = payload + "=" * ((4 - payload.length % 4) % 4)
            JSON.parse(Base64.urlsafe_decode64(padded))
          end
        end

        def fetch_profile
          url = URI.join(options.api_base_url, "profile").to_s
          id_token = access_token["id_token"]

          response = Faraday.get(url) do |req|
            req.headers["Authorization"] = "Bearer #{id_token}"
            req.headers["Accept"] = "application/json"
          end

          JSON.parse(response.body)
        end
    end
  end
end
