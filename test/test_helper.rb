require 'simplecov'
require 'lib/extensions.rb'
SimpleCov.start

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'cloudconvert-ruby'
require 'minitest/autorun'
require 'webmock/minitest'
