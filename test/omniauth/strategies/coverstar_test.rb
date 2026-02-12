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
    assert_equal "https://auth.coverstar.app", @strategy.options.client_options.site
  end

  def test_client_authorize_url
    assert_equal "/login", @strategy.options.client_options.authorize_url
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
      client_options: { site: "https://auth-dev.coverstar.app" }
    )
    assert_equal "https://auth-dev.coverstar.app", strategy.options.client_options.site
  end

  def test_uid_from_id_token
    sub = "abc-123-def-456"
    strategy = build_strategy_with_access_token(sub: sub)

    assert_equal sub, strategy.uid
  end

  def test_info_email_from_id_token
    strategy = build_strategy_with_access_token(
      sub: "abc-123",
      email: "user@example.com",
      username: "janedoe"
    )

    assert_equal "user@example.com", strategy.info[:email]
    assert_equal "janedoe", strategy.info[:name]
  end

  def test_info_with_missing_fields
    strategy = build_strategy_with_access_token(sub: "abc-123")

    assert_nil strategy.info[:email]
    assert_nil strategy.info[:name]
  end

  def test_credentials_include_id_token
    strategy = build_strategy_with_access_token(sub: "abc-123")

    creds = strategy.credentials
    assert_equal "mock_access_token", creds["token"]
    assert creds["id_token"]
    assert creds["expires"]
  end

  def test_credentials_include_refresh_token
    strategy = build_strategy_with_access_token(sub: "abc-123", refresh_token: "mock_refresh")

    assert_equal "mock_refresh", strategy.credentials["refresh_token"]
  end

  def test_extra_raw_info_contains_decoded_id_token
    strategy = build_strategy_with_access_token(
      sub: "abc-123",
      email: "user@example.com",
      username: "janedoe"
    )

    raw = strategy.extra[:raw_info]
    assert_equal "abc-123", raw["sub"]
    assert_equal "user@example.com", raw["email"]
    assert_equal "janedoe", raw["cognito:username"]
  end

  def test_callback_url_strips_query_params
    strategy = OmniAuth::Strategies::Coverstar.new(@app, "client_id", "client_secret")

    env = Rack::MockRequest.env_for(
      "https://example.com/auth/coverstar/callback?code=abc&state=xyz",
      "REQUEST_METHOD" => "GET"
    )
    strategy.instance_variable_set(:@env, env)

    url = strategy.send(:callback_url)
    refute_includes url, "?"
    assert url.end_with?("/auth/coverstar/callback")
  end

  private

  def build_jwt(sub:, email: nil, username: nil)
    header = Base64.urlsafe_encode64('{"alg":"RS256","typ":"JWT"}', padding: false)
    claims = { "sub" => sub, "iss" => "cognito" }
    claims["email"] = email if email
    claims["cognito:username"] = username if username
    payload = Base64.urlsafe_encode64(JSON.generate(claims), padding: false)
    signature = Base64.urlsafe_encode64("fakesig", padding: false)
    "#{header}.#{payload}.#{signature}"
  end

  def build_strategy_with_access_token(sub:, email: nil, username: nil, refresh_token: nil)
    id_token = build_jwt(sub: sub, email: email, username: username)
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

    client = OAuth2::Client.new("client_id", "client_secret", site: "https://auth.coverstar.app")
    token = OAuth2::AccessToken.from_hash(client, token_hash)
    strategy.instance_variable_set(:@access_token, token)
    strategy
  end
end
