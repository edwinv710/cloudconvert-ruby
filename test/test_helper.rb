require 'simplecov'
SimpleCov.start

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'cloudconvert-ruby'
require 'minitest/autorun'
require 'webmock/minitest'
require 'lib/environment.rb'
#WebMock.allow_net_connect!
#WebMock.disable_net_connect!(allow_localhost: true)