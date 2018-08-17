require 'base64'
require 'pathname'

module CloudConvert

  class Process
    attr_reader :client,
                :input_format,
                :output_format,
                :process_response,
                :conversion_response,
                :status_response,
                :download_url,
                :step,
                :mode



    def initialize(args = {})
      @input_format = args[:input_format]
      @output_format = args[:output_format]
      @step = :awaiting_creation
      @mode = args[:mode] || 'convert'
      @client = args[:client]
    end

    def create
        raise CloudConvert::InvalidStep unless @step == :awaiting_creation
        url = construct_url("process")
        response = send_request(http_method: :post,
                                url: url,
                                params: {
                                    "apikey" => @client.api_key,
                                    "inputformat" => @input_format,
                                    "outputformat" => @output_format,
                                    "mode" => @mode,
                                }) do | response|
            @step = :awaiting_conversion
            response.parsed_response[:success] = true
            create_parsed_response(:process_response, response.parsed_response)
        end
        return convert_response response
    end

    def convert(opts)
        raise CloudConvert::InvalidStep if @step == :awaiting_creation
        url = process_url()
        if opts[:file].respond_to?("read")
          file_to_upload = opts[:file]
          opts.delete(:file)
        end
        response = send_request(http_method: :post, 
                                url: url, 
                                params: opts,
                                multi: false) do |response|
            response.parsed_response[:success] = true
            create_parsed_response(:conversion_response, response.parsed_response)
            @step = @conversion_response[:step].to_sym

            if(file_to_upload)
              send_request(http_method: :post,
                           url: "#{CloudConvert::PROTOCOL}:#{@conversion_response[:upload][:url]}",
                           params: {
                               "file": file_to_upload
                           },
                           multi: true)
            end

        end
        return convert_response response
    end

    def status
        raise CloudConvert::InvalidStep if @step == :awaiting_creation
        url = process_url()
        response = send_request(http_method: :get,
                                url: url) do |response|
            create_parsed_response(:status_response, response.parsed_response)
            @step = @status_response[:step].to_sym
        end
        return convert_response response
    end

    def download(path, file_name="")    
        raise CloudConvert::InvalidStep if @step == :awaiting_creation
        response =  HTTMultiParty.get(download_url(file_name))
        return update_download_progress response unless response.response.code == "200"
        file_name = response.response.header['content-disposition'][/filename=(\"?)(.+)\1/, 2] if file_name.strip.empty?
        full_path = full_path(path, file_name)
        return full_path.open("w") do |f| 
            f.binmode
            f.write response.parsed_response
            full_path.to_s
        end
    end

    def delete
        raise CloudConvert::InvalidStep if @step == :awaiting_creation
        url = construct_url(process_response[:subdomain], "process", process_response[:id])
        response = HTTMultiParty.delete(url)
        @step = :deleted if response.response.code == "200"
        return convert_response response
    end

    def download_url(file = "")
        raise CloudConvert::InvalidStep if @step == :awaiting_creation
        file = "/#{file}" unless file.nil? or file.strip.empty?
        return "#{CloudConvert::PROTOCOL}:#{@conversion_response[:output][:url]}#{file}"
    end

    
    private

    def send_request(opts)
        request =  opts[:params] || {}
        args = [opts[:http_method], opts[:url], {query: request, detect_mime_type: (true if opts[:multi])}]
        response = CloudConvert::Client.send(*args)
        yield(response) if block_given? and (response.response.code == "200" || 
            (response.parsed_response.kind_of?(Hash) and response.parsed_response.key?("step")))
        return response
    end

    def construct_url(action, id="")
      id = "/#{id}" if id.length > 0
      return "#{CloudConvert::PROTOCOL}://#{CloudConvert::API_DOMAIN}/#{action}#{id}"
    end

    def process_url()
        return "#{CloudConvert::PROTOCOL}:#{@process_response[:url]}"
    end


    def create_parsed_response(variable_symbol, parsed_response)
        symbolized_response = parsed_response.deep_symbolize
        return self.instance_variable_set("@#{variable_symbol.to_s}", symbolized_response)
    end


    def convert_response(response)
        case @client.return_type
        when :response
            return response.response
        else
            parsed_response = response.parsed_response.deep_symbolize
            return parsed_response
        end
    end

    def full_path(dir, file_name)
        return Pathname(dir).join(file_name)
    end

    def update_download_progress(response)
        if response.parsed_response["step"]
            create_parsed_response(:status_response, response.parsed_response)
            @step = @status_response[:step].to_sym
        end
        return convert_response response
    end

  end
end
