require 'test_helper'
require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = "test/support/vcr_fixtures/vcr_cassettes"
  config.hook_into :webmock 
  config.default_cassette_options = {
    :match_requests_on => [:method,
      VCR.request_matchers.uri_without_param(:apikey)]
  }
end


class ClientTest < Minitest::Test

  def setup
    @client_without_processes = CloudConvert::Client.new(api_key: "api_key")
    @client = CloudConvert::Client.new(api_key: "")
    @process = @client.build_process(input_format: "jpg", output_format: "pdf")
  end

  def test_that_it_stores_and_reads_the_correct_api_key
    assert_equal @client_without_processes.api_key, "api_key"
  end

  def test_that_it_returns_an_empty_array_of_processes_if_not_are_added_in_inizilization
    assert_empty @client_without_processes.processes
  end

  def test_that_it_returns_the_processes_added_in_the_initializer
    process_one   = CloudConvert::Process.new(input_format: "flv", input_format: "mp4")
    process_two   = CloudConvert::Process.new(input_format: "erb", input_format: "html")
    process_three = CloudConvert::Process.new(input_format: "force", input_format: "darkside")

    client = CloudConvert::Client.new(api_key: "api_key", processes: [process_one, process_two, process_three])

    assert_equal    client.processes.size, 3
    assert_includes client.processes, process_one
    assert_includes client.processes, process_two
    assert_includes client.processes, process_three
  end

  def test_that_it_can_build_a_process
    process = @client_without_processes.build_process(input_format: "flv", input_format: "mp4")
    assert_kind_of CloudConvert::Process, process
  end

  def test_that_it_stores_all_processes
    process_one   = @client_without_processes.build_process(input_format: "flv", input_format: "mp4")
    process_two   = @client_without_processes.build_process(input_format: "erb", input_format: "html")
    process_three = @client_without_processes.build_process(input_format: "force", input_format: "darkside")

    assert_equal    @client_without_processes.processes.size, 3
    assert_includes @client_without_processes.processes, process_one
    assert_includes @client_without_processes.processes, process_two
    assert_includes @client_without_processes.processes, process_three
  end

  def test_that_we_can_set_the_return_type
    @client_without_processes.return_type = :request
    assert_equal :request, @client_without_processes.return_type
  end

  def test_that_list_returns_an_array_of_hashes
    VCR.use_cassette("create_jpg_pdf_2") { @process.create }
    VCR.use_cassette("convert_jpg_pdf_2") do
      @conversion_response = @process.convert(
        input: "download",
        outputformat: "pdf", 
        file: "http://hdwallpaperslovely.com/wp-content/gallery/royalty-free-images-free/royalty-free-stock-images-raindrops-01.jpg",
        download: "false"
      )
    end
    VCR.use_cassette("list_conversions"){@list = @client.list}
    assert_equal true, @list.kind_of?(Array)
    @list.each { |list| assert_equal true, list.kind_of?(Hash) }
  end
end
