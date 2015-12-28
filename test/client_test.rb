require 'test_helper'

class ClientTest < Minitest::Test

  def setup
    @client_without_processes = CloudConvert::Client.new(api_key: "api_key")
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

  def test_that_we_can_set_the_api_key
    @client_without_processes.set_api_key("testing")
    assert_equal "testing", @client_without_processes.api_key
  end

end
