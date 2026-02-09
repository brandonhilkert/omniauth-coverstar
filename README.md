# OmniAuth Coverstar

OmniAuth OAuth2 strategy for authenticating with the Coverstar/Spotlight platform via AWS Cognito.

## Installation

Add to your Gemfile:

```ruby
gem "omniauth-coverstar"
```

## Usage

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :coverstar,
    ENV["COVERSTAR_CLIENT_ID"],
    ENV["COVERSTAR_CLIENT_SECRET"]
end
```

### Configuration Options

```ruby
provider :coverstar,
  ENV["COVERSTAR_CLIENT_ID"],
  ENV["COVERSTAR_CLIENT_SECRET"],
  scope: "openid email profile",
  api_base_url: "https://api-dev.spotlight.social/external-v1-dev/",
  client_options: {
    site: "https://spotlight.auth.us-east-1.amazoncognito.com"
  }
```

| Option | Default | Description |
|--------|---------|-------------|
| `scope` | `"openid email profile"` | OAuth scopes to request |
| `api_base_url` | `"https://api.spotlight.social/external-v1/"` | Spotlight profile API base URL. Use `https://api-dev.spotlight.social/external-v1-dev/` for development. |
| `client_options[:site]` | `"https://spotlight.auth.us-east-1.amazoncognito.com"` | Cognito OAuth domain |

## Auth Hash

```ruby
{
  uid: "cognito-sub-uuid",
  info: {
    email: "user@example.com",
    name: "Preferred Name",
    description: "User bio"
  },
  credentials: {
    token: "access_token",
    id_token: "jwt_id_token",
    refresh_token: "refresh_token",
    expires_at: 1234567890,
    expires: true
  },
  extra: {
    raw_info: {
      data: {
        email: "user@example.com",
        preferredName: "Preferred Name",
        description: "User bio"
      }
    }
  }
}
```

## License

MIT
