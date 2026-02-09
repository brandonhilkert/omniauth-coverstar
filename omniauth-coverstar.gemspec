require_relative "lib/omniauth/coverstar/version"

Gem::Specification.new do |spec|
  spec.name          = "omniauth-coverstar"
  spec.version       = OmniAuth::Coverstar::VERSION
  spec.authors       = ["Brandon Hilkert"]
  spec.email         = ["brandonhilkert@gmail.com"]

  spec.summary       = "OmniAuth strategy for Coverstar/Spotlight OAuth2"
  spec.description   = "OmniAuth OAuth2 strategy for authenticating with the Coverstar/Spotlight platform via AWS Cognito."
  spec.homepage      = "https://github.com/brandonhilkert/omniauth-coverstar"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.files         = Dir["lib/**/*", "LICENSE.txt", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "omniauth", ">= 1.9", "< 3"
  spec.add_dependency "omniauth-oauth2", "~> 1.7"

  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "webmock", "~> 3.18"
  spec.add_development_dependency "rack-test", "~> 2.0"
end
