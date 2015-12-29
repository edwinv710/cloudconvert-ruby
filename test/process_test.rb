#TODO Setup init function as a module or find an alternative.

require 'test_helper'
require 'minitest/autorun'
require "base64"

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
    it "should return the string 'jpg'" do
      @process.input_format.must_equal "jpg"  
    end
  end

  describe "#output_format" do
    it "should return the string 'pdf'" do
      @process.output_format.must_equal "pdf"  
    end
  end

  describe "#client" do
    it "should never be nil" do
      @anonymous_process.client.wont_be_nil
    end
  end

  describe "#create" do
    it "should return a Hash with the relevant information in the response" do
      @process.create.kind_of?(Hash).must_equal true
    end

    it "should run if the step for that process is not :awaiting_process_creation" do
      @process.create
      assert_raises CloudConvert::InvalidStep do
        @process.create
      end
    end

    it "should not change the step if the argument passed are incomplete" do
         @process.client.instance_variable_set("@api_key", "")
         @process.create
         @process.step.must_equal :awaiting_process_creation
    end
  end

  describe "#process_response" do
    it "should be nil if the process has not been created" do
      @process.process_response.must_be_nil
    end

    it "should not be nil" do
      @process.create
      @process.process_response.wont_be_nil
    end

    it "should be the correct response" do
      @process.create
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

    it "should return an HTTP response if successful" do
      response = @process.convert({
                        input: "download",
                        outputformat: "pdf", 
                        file: "http://hdwallpaperslovely.com/wp-content/gallery/royalty-free-images-free/royalty-free-stock-images-raindrops-01.jpg",
                        download: "false"
                        })
      response.kind_of?(Hash).must_equal true
    end

    it "should be able to send a file" do
      path = File.dirname(__FILE__) + '/output/image.jpg'
      response = @process.convert({
                        input: "file",
                        outputformat: "file", 
                        file: File.new(path),
                        download: "false"
                        })
      response.kind_of?(Hash).must_equal true
    end

    it "should only change the step if response from convert is successful" do
      @process.convert({
        input: "mp4",
        file: "blah",
        download: "false"
      })
      @process.step.must_equal :awaiting_conversion
    end
  end

#
# ---------> Bookmark
#
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

    it "should return an http response if successful" do
      @process.status.kind_of?(Hash).must_equal true
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

    it "should return a symbolized version of the step if the status has changes" do
      @process.create
      @process.convert({
        input: "download",
        outputformat: "pdf", 
        file: "http://hdwallpaperslovely.com/wp-content/gallery/royalty-free-images-free/royalty-free-stock-images-raindrops-01.jpg",
        download: "false"
      })
      @process.status
      process_hash = @process.process_response
      process_hash[:id] = "12345"
      @process.instance_variable_set("@process_response", process_hash)
      puts "Process Id: #{@process.process_response[:id]}"
      @process.status
      @process.step.must_equal :finished
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

    it "should downloads the file and add it to the directory specified if a path is provided" do
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
      @process.delete.kind_of?(Hash).must_equal true
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
      @process.client.api_key.must_equal ""
      @process.list[:code].must_equal '400'
    end

    it "should return a non-empty hash if the request was successful" do
      @process.list.kind_of?(Array).must_equal true
      @process.list.size.must_equal 3
    end

  end

end