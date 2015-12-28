require 'test_helper'

class CloudConvertTest < Minitest::Test

  def test_that_it_has_a_version_number
    refute_nil CloudConvert::VERSION
  end

  def test_that_it_has_a_protocol_and_domain_static_variables
    refute_nil CloudConvert::DOMAIN
    refute_nil CloudConvert::PROTOCOL
  end

end
