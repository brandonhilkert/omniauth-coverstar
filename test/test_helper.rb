require "minitest/autorun"
require "webmock/minitest"
require "rack/test"
require "omniauth"
require "omniauth-coverstar"

OmniAuth.config.test_mode = true
