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

      uid { decoded_id_token["sub"] }

      info do
        {
          email: decoded_id_token["email"],
          name:  decoded_id_token["cognito:username"]
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
        { raw_info: decoded_id_token }
      end

      private
        def callback_url
          options[:redirect_uri] || (full_host + script_name + callback_path)
        end

        def decoded_id_token
          @decoded_id_token ||= begin
            id_token = access_token["id_token"]
            payload = id_token.split(".")[1]
            padded = payload + "=" * ((4 - payload.length % 4) % 4)
            JSON.parse(Base64.urlsafe_decode64(padded))
          end
        end
    end
  end
end
