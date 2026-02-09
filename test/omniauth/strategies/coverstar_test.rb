require "test_helper"

class OmniAuth::Strategies::CoverstarTest < Minitest::Test
  def setup
    @app = ->(_env) { [200, {}, ["OK"]] }
    @strategy = OmniAuth::Strategies::Coverstar.new(@app, "client_id", "client_secret")
  end

  def test_strategy_name
    assert_equal "coverstar", @strategy.options.name
  end

  def test_client_site
    assert_equal "https://spotlight.auth.us-east-1.amazoncognito.com", @strategy.options.client_options.site
  end

  def test_client_authorize_url
    assert_equal "/oauth2/authorize", @strategy.options.client_options.authorize_url
  end

  def test_client_token_url
    assert_equal "/oauth2/token", @strategy.options.client_options.token_url
  end

  def test_default_scope
    assert_equal "openid email profile", @strategy.options.scope
  end

  def test_default_api_base_url
    assert_equal "https://api.spotlight.social/external-v1/", @strategy.options.api_base_url
  end

  def test_custom_api_base_url
    strategy = OmniAuth::Strategies::Coverstar.new(
      @app, "client_id", "client_secret",
      api_base_url: "https://api-dev.spotlight.social/external-v1-dev/"
    )
    assert_equal "https://api-dev.spotlight.social/external-v1-dev/", strategy.options.api_base_url
  end

  def test_custom_site
    strategy = OmniAuth::Strategies::Coverstar.new(
      @app, "client_id", "client_secret",
      client_options: { site: "https://custom.auth.example.com" }
    )
    assert_equal "https://custom.auth.example.com", strategy.options.client_options.site
  end

  def test_uid_from_id_token
    sub = "abc-123-def-456"
    strategy = build_strategy_with_access_token(sub: sub)

    assert_equal sub, strategy.uid
  end

  def test_info_from_profile_api
    sub = "abc-123"
    profile_data = {
      "data" => {
        "email" => "user@example.com",
        "preferredName" => "Jane Doe",
        "description" => "A bio"
      }
    }

    strategy = build_strategy_with_access_token(sub: sub, profile_response: profile_data)

    assert_equal "user@example.com", strategy.info[:email]
    assert_equal "Jane Doe", strategy.info[:name]
    assert_equal "A bio", strategy.info[:description]
  end

  def test_info_with_missing_fields
    sub = "abc-123"
    profile_data = { "data" => { "email" => "user@example.com" } }

    strategy = build_strategy_with_access_token(sub: sub, profile_response: profile_data)

    assert_equal "user@example.com", strategy.info[:email]
    assert_nil strategy.info[:name]
    assert_nil strategy.info[:description]
  end

  def test_credentials_include_id_token
    sub = "abc-123"
    strategy = build_strategy_with_access_token(sub: sub)

    creds = strategy.credentials
    assert_equal "mock_access_token", creds["token"]
    assert creds["id_token"]
    assert creds["expires"]
  end

  def test_credentials_include_refresh_token
    sub = "abc-123"
    strategy = build_strategy_with_access_token(sub: sub, refresh_token: "mock_refresh")

    assert_equal "mock_refresh", strategy.credentials["refresh_token"]
  end

  def test_extra_raw_info
    sub = "abc-123"
    profile_data = { "data" => { "email" => "user@example.com" } }
    strategy = build_strategy_with_access_token(sub: sub, profile_response: profile_data)

    assert_equal profile_data, strategy.extra[:raw_info]
  end

  def test_profile_api_uses_id_token_as_bearer
    sub = "abc-123"
    id_token = build_jwt(sub: sub)

    stub_request(:get, "https://api.spotlight.social/external-v1/profile")
      .with(headers: { "Authorization" => "Bearer #{id_token}" })
      .to_return(status: 200, body: '{"data":{}}', headers: { "Content-Type" => "application/json" })

    strategy = build_strategy_with_token(id_token: id_token, access_token: "different_access_token")
    strategy.raw_info

    assert_requested(:get, "https://api.spotlight.social/external-v1/profile",
      headers: { "Authorization" => "Bearer #{id_token}" })
  end

  def test_callback_url_strips_query_params
    strategy = OmniAuth::Strategies::Coverstar.new(@app, "client_id", "client_secret")

    env = Rack::MockRequest.env_for(
      "https://example.com/auth/coverstar/callback?code=abc&state=xyz",
      "REQUEST_METHOD" => "GET"
    )
    strategy.instance_variable_set(:@env, env)

    url = strategy.callback_url
    refute_includes url, "?"
    assert url.end_with?("/auth/coverstar/callback")
  end

  private

  def build_jwt(sub:)
    header = Base64.urlsafe_encode64('{"alg":"RS256","typ":"JWT"}', padding: false)
    payload = Base64.urlsafe_encode64(JSON.generate({ "sub" => sub, "iss" => "cognito" }), padding: false)
    signature = Base64.urlsafe_encode64("fakesig", padding: false)
    "#{header}.#{payload}.#{signature}"
  end

  def build_strategy_with_access_token(sub:, profile_response: nil, refresh_token: nil)
    id_token = build_jwt(sub: sub)
    profile_response ||= { "data" => {} }

    stub_request(:get, "https://api.spotlight.social/external-v1/profile")
      .to_return(status: 200, body: JSON.generate(profile_response), headers: { "Content-Type" => "application/json" })

    build_strategy_with_token(id_token: id_token, access_token: "mock_access_token", refresh_token: refresh_token)
  end

  def build_strategy_with_token(id_token:, access_token: "mock_access_token", refresh_token: nil)
    strategy = OmniAuth::Strategies::Coverstar.new(@app, "client_id", "client_secret")

    token_hash = {
      "access_token" => access_token,
      "token_type" => "Bearer",
      "expires_in" => 3600,
      "id_token" => id_token
    }
    token_hash["refresh_token"] = refresh_token if refresh_token

    client = OAuth2::Client.new("client_id", "client_secret", site: "https://spotlight.auth.us-east-1.amazoncognito.com")
    token = OAuth2::AccessToken.from_hash(client, token_hash)
    strategy.instance_variable_set(:@access_token, token)
    strategy
  end
end
