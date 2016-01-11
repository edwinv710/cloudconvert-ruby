require 'test_helper'

require 'vcr'

VCR.configure do |config|
  config.cassette_library_dir = "test/support/vcr_fixtures/vcr_cassettes"
  config.hook_into :webmock 
end

describe CloudConvert::Process, "VCR Process Test" do

  before :all do
    @process_options = {input_format: "jpg", output_format: "pdf"}
    @client = CloudConvert::Client.new(api_key: "")
    @process = @client.build_process(@process_options)
  end

  describe "#client" do
    it "should return the client that built the process" do
      @process.client.must_equal @client
    end
    it "should return a client even if the client is not built externally" do
      @anonymous_process = CloudConvert::Process.new(@process_options)
      @anonymous_process.client.kind_of?(CloudConvert::Client).must_equal true
    end
  end

  describe "#create" do

    describe "when the proccess creation was successful" do
      before :all do
        VCR.use_cassette("create_jpg_pdf") do
          @process_response = @process.create
        end
      end
      it "should return a Hash with the relevant information in the response" do
        @process_response.kind_of?(Hash).must_equal true
      end
      it "should raise an invalid step exception if a process was already created." do
        assert_raises CloudConvert::InvalidStep do
          @process.create
        end
      end
    end
    
    describe "when the process creation was unsuccessful" do
      it "should not change the step" do
        @process.client.instance_variable_set("@api_key", "")
        VCR.use_cassette("create_jpg_pdf_error") { @process.create }
        @process.step.must_equal :awaiting_creation
      end
      it "should return error code 401" do
        @process.client.instance_variable_set("@api_key", "")
        VCR.use_cassette("create_jpg_pdf_error") do 
          @process.create[:code].must_equal 401 
        end
      end
    end
  
  end

  describe "#process_response" do

    describe "when the create method was not successful or it has not run yet" do
      it "should be nil" do
        @process.process_response.must_be_nil
      end
    end

    describe "when the create method was successful" do
      before :all do
        VCR.use_cassette("create_jpg_pdf") { @parsed_response = @process.create }
      end
      it "should equal the value returned by create minus the :subdomain value" do
        @process.process_response.reject{|key, value| key == :subdomain}.must_equal @parsed_response
      end
      it "should have a key called :subdomain with a value" do
        @process.process_response[:subdomain].size.must_be :>, 0
      end
      it "should have a key called :success and it should map to the value true" do
        @parsed_response[:success].must_equal true
      end
    end

  end

  describe "#convert" do

    describe "when a process has not been created" do
      it "should raise a CloudConvert::InvalidStep" do
        assert_raises CloudConvert::InvalidStep do
          @process.convert({
            input: "mp4",
            file: "blah",
            download: "false"
          })
        end
      end
    end

    describe "when the conversion method was sucessful passing a url as the file" do
      before :all do
        VCR.use_cassette("create_jpg_pdf") { @process.create }
        VCR.use_cassette("convert_jpg_pdf") do
          @conversion_response = @process.convert(
            input: "download",
            outputformat: "pdf", 
            file: "http://hdwallpaperslovely.com/wp-content/gallery/royalty-free-images-free/royalty-free-stock-images-raindrops-01.jpg",
            download: "false"
          )
        end
      end
      it "should return a hash" do
        @conversion_response.kind_of?(Hash).must_equal true
      end
      it "should set the process set to the step of the response" do
        @process.step.must_equal @conversion_response[:step].to_sym
      end
      it "should return a hash with a key called :success that maps to the value true" do
        @conversion_response[:success].must_equal true
      end
      it "should return a step" do
        @conversion_response.key?(:step).must_equal true
        @conversion_response[:step].size.must_be :>, 0
      end
    end

    describe "when the conversion method was successful when uploading a file" do

      before :all do
        VCR.use_cassette("create_jpg_pdf_file_upload") { @process.create }
        VCR.use_cassette("convert_jpg_pdf_file_upload") do
          file_path = File.dirname(__FILE__) + '/input/raindrops-01.jpg'
          File.open(file_path) do |file|
            upload_file = UploadIO.new(file, "image/jpeg", "raindrops-01.jpg")
            @conversion_response = @process.convert(
              input: "upload",
              outputformat: "pdf", 
              file: upload_file,
              download: "false"
            )
          end
        end
      end
      it "should return a hash" do
        @conversion_response.kind_of?(Hash).must_equal true
      end
      it "should set the process set to the step of the response" do
        @process.step.must_equal @conversion_response[:step].to_sym
      end
      it "should return a hash with a key called :success that maps to the value true" do
        @conversion_response[:success].must_equal true
      end
      it "should return a step" do
        @conversion_response.key?(:step).must_equal true
        @conversion_response[:step].size.must_be :>, 0
      end
    end   
  end

  describe "#status" do

    describe "when the conversion was successful" do
      before :all do
        VCR.use_cassette("create_jpg_pdf") { @process.create }
        VCR.use_cassette("convert_jpg_pdf") do
          @conversion_response = @process.convert(
            input: "download",
            outputformat: "pdf", 
            file: "http://hdwallpaperslovely.com/wp-content/gallery/royalty-free-images-free/royalty-free-stock-images-raindrops-01.jpg",
            download: "false"
          )
        end
        VCR.use_cassette("status_jpg_pdf") {@status = @process.status }
      end
      it "should return a hash" do
        @status.kind_of?(Hash).must_equal true
      end
      it "should set the step to to a symbolized version of the response" do
        @process.step.must_equal @status[:step].to_sym
      end
    end

    describe "when an error has occured during the conversion process" do
      before :all do
        VCR.use_cassette("create_jpg_pdf_conversion_error") { @process.create }
        VCR.use_cassette("convert_jpg_pdf_conversion_error") do
          @process.convert({
            input: "mp4",
            file: "blah",
            download: "false"
          })
        end
        VCR.use_cassette("status_jpg_pdf_error") {@status = @process.status }
      end
      it "return a hash with a step of error" do
        @status[:step].must_equal "error"
      end
      it "should set the current step of process to 'error'" do
        @process.step.must_equal :error
      end
    end

    describe "when a process has yet to be created" do
      it "should raise an InvalidStep exception" do
        assert_raises CloudConvert::InvalidStep do
          VCR.use_cassette("convert_jpg_pdf") do
            @conversion_response = @process.status
          end
        end
      end
    end

  end

  describe "#download" do

    describe "when a conversion was successful" do
      before :all do
        @path = File.join(File.dirname(__FILE__), "output")
        VCR.use_cassette("create_jpg_pdf") { @process.create }
        VCR.use_cassette("convert_jpg_pdf") do
          @conversion_response = @process.convert(
            input: "download",
            outputformat: "pdf", 
            file: "http://hdwallpaperslovely.com/wp-content/gallery/royalty-free-images-free/royalty-free-stock-images-raindrops-01.jpg",
            download: "false"
          )
        end
        VCR.use_cassette("download_jpg_pdf") { @download = @process.download(@path) }
      end
      it "should return a string that includes the path" do
        @download.include?(@path).must_equal true
      end
      it "should add a file with a full path returned by download" do
        File.exist?(@download).must_equal true
      end
    end

    describe "when a conversion was successful while uploading a file" do
       before :all do
        @path = File.join(File.dirname(__FILE__), "output")
        VCR.use_cassette("create_jpg_pdf_file_upload") { @process.create }
        VCR.use_cassette("convert_jpg_pdf_file_upload") do
          file_path = File.dirname(__FILE__) + '/input/raindrops-01.jpg'
          File.open(file_path) do |file|
            upload_file = UploadIO.new(file, "image/jpeg", "raindrops-01.jpg")
            @conversion_response = @process.convert(
              input: "upload",
              outputformat: "pdf", 
              file: upload_file,
              download: "false"
            )
          end
        end
        VCR.use_cassette("download_jpg_pdf_file_upload") { @download = @process.download(@path) }
      end

      it "should return a string that includes the path" do
        @download.include?(@path).must_equal true
      end

      it "should add a file with a full path returned by download" do
        File.exist?(@download).must_equal true
      end
    end

    describe "when a conversion was successful and produced multiple output files" do
      before :all do
        @process_options = {input_format: "pdf", output_format: "html"}
        @process = @client.build_process(@process_options)
        @path = File.join(File.dirname(__FILE__), "output")
        VCR.use_cassette("create_pdf_html") { @process.create }
        VCR.use_cassette("convert_pdf_html") do
          @conversion_response = @process.convert(
            input: "download",
            outputformat: "html", 
            file: "http://www.digilife.be/quickreferences/qrc/ruby%20language%20quickref.pdf",
            download: "false",
            save: "true",
            converteroptions: {
              embed_css: "false",
              embed_javascript: "false"
            }
          )
        end
        VCR.use_cassette("status_pdf_html") { @status = @process.status }
        VCR.use_cassette("download_pdf_html") { @download = @process.download(@path) }
      end

      it "should return a string that includes the path" do
        @download.include?(@path).must_equal true
      end

      it "should add a zip with the full path returned by download" do
        File.exist?(@download).must_equal true
      end

      it "should be able to download an individial file returned by the status" do
        file_name = "base.min.css"
        VCR.use_cassette("download_individual_pdf_html") { @individual_file = @process.download(@path, file_name) }
        File.exist?(@individual_file).must_equal true
        @individual_file.include?(file_name).must_equal true

      end
    end

    describe "when there was an error in the conversion" do
      before :all do
        path = File.dirname(__FILE__) + '/output/'
        VCR.use_cassette("create_jpg_pdf_conversion_error") { @process.create }
        VCR.use_cassette("convert_jpg_pdf_conversion_error") do
          @process.convert({
            input: "mp4",
            file: "blah",
            download: "false"
          })
        end
        VCR.use_cassette("download_jpg_pdf_conversion_error") {@download = @process.download(path)}
      end

      it "should return a hash instead of the amount of bytes written" do
        @download.kind_of?(Hash).must_equal true
      end

      it "should set the step to error" do
        @process.step.must_equal :error
      end

      it "should set the status hash value to the returned response" do
        @process.status_response.must_equal @download
      end
    end

    describe "when a process has yet to be created" do
      it "should raise an InvalidStep exception" do
        assert_raises CloudConvert::InvalidStep do
          path = File.dirname(__FILE__) + '/output/'
          @path = @process.download(path)
        end
      end
    end


  end

  describe "#delete" do

    describe "when a process was successfully created" do
      before :all do
        VCR.use_cassette("create_jpg_pdf") { @process.create }
        VCR.use_cassette("convert_jpg_pdf") do
          @conversion_response = @process.convert(
            input: "download",
            outputformat: "pdf", 
            file: "http://hdwallpaperslovely.com/wp-content/gallery/royalty-free-images-free/royalty-free-stock-images-raindrops-01.jpg",
            download: "false"
          )
        end
        VCR.use_cassette("delete_jpg_pdf"){@delete_response = @process.delete}
      end
      it "should return a hash" do
        @delete_response.kind_of?(Hash).must_equal true
      end

      it "should set step to :deleted if the request was successful" do
        @process.step.must_equal :deleted
      end
    end

    describe "when a process has yet to be created" do
      it "should raise an InvalidStep exception" do
        assert_raises CloudConvert::InvalidStep do
          @path = @process.delete
        end
      end
    end

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

  describe "the clients return type is set to response" do
    it "should return a responses with a return type of Net::HTTPResponse" do
      @process.client.return_type = :response
      VCR.use_cassette("create_jpg_pdf") { @create_response = @process.create }
      VCR.use_cassette("convert_jpg_pdf") do
        @conversion_response = @process.convert(
          input: "download",
          outputformat: "pdf", 
          file: "http://hdwallpaperslovely.com/wp-content/gallery/royalty-free-images-free/royalty-free-stock-images-raindrops-01.jpg",
          download: "false"
        )
      end
      VCR.use_cassette("status_jpg_pdf") {@status_response = @process.status }
      @create_response.kind_of?(Net::HTTPResponse).must_equal true
      @conversion_response.kind_of?(Net::HTTPResponse).must_equal true
      @status_response.kind_of?(Net::HTTPResponse).must_equal true
    end
  end

  
end