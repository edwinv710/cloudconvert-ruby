$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'cloud_convert'
require 'minitest/autorun'
require 'webmock/minitest'
require 'support/fake_cloud_convert.rb'
#WebMock.allow_net_connect!
#WebMock.disable_net_connect!(allow_localhost: true)