#TODO Setup init function as a module or find an alternative.

require 'test_helper'
require 'minitest/autorun'

describe CloudConvert::Process, "Process test" do
  # let(:process_options) { {input_format: "jpg", output_format: "pdf"} }
  # let(:client) { CloudConvert::Client.new(api_key: "7mWZZkBjRqGN224WzW4P6sXha8ic7I37CRufh5DlY04ZPxlkgn8Cw1xXAliS0QGZg80kwZWe-A6P5r8ZNmlVKg") }
  # let(:process) { client.build_process(input_format: "jpg", output_format: "pdf") }
  # let(:anonymous_process) { CloudConvert::Process.new(input_format: "jpg", output_format: "pdf") }
  # let(:response) do 
  #   process.create 
  # end

  before :all do
    stub_request(:any, /cloudconvert.com/).to_rack(FakeCloudConvert)
    @process_options = {input_format: "jpg", output_format: "pdf"}
    @client = CloudConvert::Client.new(api_key: "7mWZZkBjRqGN224WzW4P6sXha8ic7I37CRufh5DlY04ZPxlkgn8Cw1xXAliS0QGZg80kwZWe-A6P5r8ZNmlVKg")
    @process = @client.build_process(@process_options)
    @anonymous_process = CloudConvert::Process.new(@process_options)
    #@response = @process.create
  end

  describe "#input_format" do
    it "should return jpg" do
      @process.input_format.must_equal "jpg"  
    end
  end

  describe "#output_format" do
    it "should return pdf" do
      @process.output_format.must_equal "pdf"  
    end
  end

  describe "#client" do
    it "should not be nil" do
      @anonymous_process.client.wont_be_nil
    end
  end

  describe "#create" do
    it "should return an http response if successful" do
      response = @process.create
      response.kind_of?(Net::HTTPSuccess).must_equal true
    end

    it "should only run create if step is awaiting process creation" do
      @process.create
      assert_raises CloudConvert::InvalidStep do
        @process.create
      end
    end

    it "should only change the step if response from create is successful" do
         @process.client.instance_variable_set("@api_key", "")
         response = @process.create
         @process.step.must_equal :awaiting_process_creation
    end
  end

  describe "#process_response" do
    before :all do
      @process.create
    end
    it "should not be nil" do
      @process.process_response.wont_be_nil
    end

    it "should be the correct response" do
      parsed_response = @process.process_response
      parsed_response[:url].to_s.wont_equal ''
      parsed_response[:id].to_s.wont_equal ''
      parsed_response[:host].to_s.wont_equal ''
      parsed_response[:expires].to_s.wont_equal ''
      parsed_response[:subdomain].to_s.wont_equal ''
    end
  end

  describe "#convert" do
    before :all do
      @process.create
    end
    it "should not be nil" do
      @process.convert({
                        input: "download",
                        outputformat: "pdf", 
                        file: "http://hdwallpaperslovely.com/wp-content/gallery/royalty-free-images-free/royalty-free-stock-images-raindrops-01.jpg",
                        download: "false"
                        }).wont_be_nil
    end

    it "should return an HTTP response if successful" do
      response = @process.convert({
                        input: "download",
                        outputformat: "pdf", 
                        file: "http://hdwallpaperslovely.com/wp-content/gallery/royalty-free-images-free/royalty-free-stock-images-raindrops-01.jpg",
                        download: "false"
                        })
      response.kind_of?(Net::HTTPSuccess).must_equal true
    end

    it "should be able to send a file" do
      path = File.dirname(__FILE__) + '/output/image.jpg'
      puts "======= #{File.new(path).inspect}"
      response = @process.convert({
                        input: "file",
                        outputformat: "file", 
                        file: File.new(path),
                        download: "false"
                        })
      response.kind_of?(Net::HTTPSuccess).must_equal true
    end

    it "should only change the step if response from convert is successful" do
      @process.convert({
        input: "mp4",
        file: "blah",
        #outputformat: "outputformat",
        download: "false"
      })
      @process.step.must_equal :awaiting_conversion
    end
  end

  describe "#status" do
    before :all do
      @process.create
      @process.convert({
                        input: "download",
                        outputformat: "pdf", 
                        file: "http://hdwallpaperslovely.com/wp-content/gallery/royalty-free-images-free/royalty-free-stock-images-raindrops-01.jpg",
                        download: "false"
                        })
    end
    it "should not be nil" do
      @process.status.wont_be_nil
    end
    it "should return an http response if successful" do
      response = @process.status
      response.kind_of?(Net::HTTPSuccess).must_equal true
    end
  end

  describe "#step" do
    it "should return awaiting process creation if process has not yet been created" do
      @process.step.must_equal :awaiting_process_creation
    end

    it "should return awaiting_conversion if process has been created but not sent for conversion" do
      @process.create
      @process.step.must_equal :awaiting_conversion
    end

    it "should return a symbolized version of the step after initiating conversion" do
      @process.create
      @process.convert({
                        input: "download",
                        outputformat: "pdf", 
                        file: "http://hdwallpaperslovely.com/wp-content/gallery/royalty-free-images-free/royalty-free-stock-images-raindrops-01.jpg",
                        download: "false"
                        })
      @process.step.must_equal :input
    end

    it "should return a symbolized version of the step after getting the status" do
      @process.create
      @process.convert({
                        input: "download",
                        outputformat: "pdf", 
                        file: "http://hdwallpaperslovely.com/wp-content/gallery/royalty-free-images-free/royalty-free-stock-images-raindrops-01.jpg",
                        download: "false"
                        })
      @process.status
      @process.step.must_equal :convert
    end

  end

  describe "download" do
    before :all do
      @process.create
      @process.convert({
                        input: "download",
                        outputformat: "pdf", 
                        file: "http://hdwallpaperslovely.com/wp-content/gallery/royalty-free-images-free/royalty-free-stock-images-raindrops-01.jpg",
                        download: "false"
                        })
    end

    it "should downloads the file and add it to the directory specified" do
      path = File.dirname(__FILE__) + '/output/image.jpg'
      File.delete(path) if File.exist?(path)
      @process.download(path)
      File.exist?(path).must_equal true
    end

  end

  describe "#delete" do
    before :all do
      @process.create
      @process.convert({
                        input: "download",
                        outputformat: "pdf", 
                        file: "http://hdwallpaperslovely.com/wp-content/gallery/royalty-free-images-free/royalty-free-stock-images-raindrops-01.jpg",
                        download: "false"
                        })
    end

    it "should return a sucessful response" do
      @process.delete.kind_of?(Net::HTTPSuccess).must_equal true
    end
  end

  describe "#list" do
    before :all do
      @process.create
      @process.convert({
                        input: "download",
                        outputformat: "pdf", 
                        file: "http://hdwallpaperslovely.com/wp-content/gallery/royalty-free-images-free/royalty-free-stock-images-raindrops-01.jpg",
                        download: "false"
                        })
    end


    it "should return an error if an api key is not found" do
      @process.client.instance_variable_set("@api_key", "")
      #puts "=====weqeqweqwe============    #{@process.client.api_key}"
      @process.client.api_key.must_equal ""
      @process.list.code.must_equal '400'
    end
  end




end

# class ProcessTest < Minitest::Test

#   @process_options = {input_format: "jpg", output_format: "pdf"}
#   @client = CloudConvert::Client.new(api_key: "7mWZZkBjRqGN224WzW4P6sXha8ic7I37CRufh5DlY04ZPxlkgn8Cw1xXAliS0QGZg80kwZWe-A6P5r8ZNmlVKg")
#   @process = @client.build_process(@process_options)
#   @anonymous_process = CloudConvert::Process.new(@process_options)
#   @response = @process.create

#   def setup
    
#   end

#   def test_that_it_has_input_and_output_format_after_initialization
#     assert_equal "jpg", @process.input_format
#     assert_equal "pdf", @process.output_format
#   end

#   def test_that_it_has_a_client_from_anonymous_process
#     refute_nil @anonymous_process.client
#   end

#   def test_that_it_has_the_correct_client_when_built_through_client
#     assert_equal @client, @process.client
#   end

#   def test_that_initial_status_is_awaiting_creation
#     assert_equal :awaiting_creation_of_process,@process.state
#   end

#   def test_that_it_returns_a_successfull_http_respnse
#     assert @response.kind_of?(Net::HTTPSuccess), @response.inspect
#   end

#   def test_that_a_process_response_is_created_after_post
#     refute_nil @process.process_response
#   end

#   def test_that_it_creates_the_correct_response_after_creating_process
#     # {"url"=>"//hostm5vajg.cloudconvert.com/process/0MYjkixLnJdE5G6qoPpa", "id"=>"0MYjkixLnJdE5G6qoPpa", "host"=>"hostm5vajg.cloudconvert.com", "expires"=>"2015-12-23 22:17:52", "maxsize"=>1024, "maxtime"=>1500, "concurrent"=>5, "minutes"=>25}
#     parsed_response = @process.process_response
#     refute_nil parsed_response[:url]
#     refute_nil parsed_response[:id]
#     refute_nil parsed_response[:host]
#     refute_nil parsed_response[:expires]
#   end
  

# end
