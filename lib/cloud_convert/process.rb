#FIXME status does not save in the initializer
#TODO Integrate the steps from the api.
require 'base64'

module CloudConvert

  class Process
    attr_reader :client,
                :input_format,
                :output_format,
                :process_response,
                :conversion_response,
                :status_response,
                :download_url,
                :step



    def initialize(args = {})
      @input_format = args[:input_format]
      @output_format = args[:output_format]
      @step = :awaiting_process_creation
      @client = args[:client] || CloudConvert::Client.new(processes: [self], return_type: args[:return_type])
    end

    def create
        raise CloudConvert::InvalidStep unless @step == :awaiting_process_creation
        url = construct_url("api", "process")
        response = send_request(http_method: :post, 
                                url: url, 
                                params: {
                                    "apikey" => @client.api_key,
                                    "inputformat" => @input_format,
                                    "outputformat" => @outputformat
                                }) do | response|
            @step = :awaiting_conversion
            create_parsed_response(:process_response, response.parsed_response)
            @process_response[:subdomain] = extract_subdomain_from_url(@process_response[:url])
        end
        return convert_response response
    end

    def convert(opts)
        url = process_url(include_process_id: true)
        multi = opts[:file].respond_to?("read")
        response = send_request(http_method: :post, 
                                url: url, 
                                params: opts,
                                multi: multi) do |response|
            create_parsed_response(:conversion_response, response.parsed_response)
            @step = @conversion_response[:step].to_sym
        end
        return convert_response response
    end

    def status
        url = process_url(include_process_id: true)
        response = send_request(http_method: :get,
                                url: url) do |response|
            create_parsed_response(:status_response, response.parsed_response)
            @step = @status_response[:step].to_sym
        end
        return convert_response response
    end

    def download(path)    
        response =  HTTMultiParty.get(download_url)
        return convert_response response unless response.response.code == "200"
        return File.open(path, "w") do |f| 
            f.binmode
            f.write response.parsed_response
        end
    end

    def delete
        url = construct_url(process_response[:subdomain], "process", process_response[:id])
        response = HTTMultiParty.delete(url)
        return convert_response response
    end

    def list
        url = construct_url("api", "processes")
        response = send_request(http_method: :get, url: url, params: {apikey: client.api_key})
        return convert_response response
    end  

    private

    def send_request(opts)
        opts[:params] ||= {}
        request =  opts[:params]
        if opts[:multi]
            url = URI.parse(opts[:url])
            req = Net::HTTP::Post::Multipart.new url.path, opts[:params]
            res = Net::HTTP.start(url.host, url.port) do |http|
              http.request(req)
            end
            request = HTTParty::Request.new(opts[:http_method], opts[:url], o = {})
            parsed_block = lambda { HTTParty::Parser.call(res. body, HTTParty::Parser.format_from_mimetype(res['content-type']))}
            response = HTTParty::Response.new(request, res, parsed_block)
        else
            response = CloudConvert::Client.send(opts[:http_method], opts[:url], query: request)
        end

        yield(response) if block_given? and response.response.code == "200"
        return response
    end

    def construct_url(subdomain, action, id="")
        id = "/#{id}" if id.length > 0
        return "#{CloudConvert::PROTOCOL}://#{subdomain}.#{CloudConvert::DOMAIN}/#{action}#{id}"
    end

    def process_url(opts = {})
        action = (opts[:include_process_id] ? "process/#{@process_response[:id]}" : "process")
        return construct_url(@process_response[:subdomain], action)
    end


    def create_parsed_response(variable_symbol, parsed_response)
        symbolized_response = parsed_response.deep_symbolize
        return self.instance_variable_set("@#{variable_symbol.to_s}", symbolized_response)
    end

    def download_url
        return "https://#{@process_response[:subdomain]}.cloudconvert.com/download/#{@process_response[:id]}"
    end

    def extract_subdomain_from_url(url)
        return url.split(".")[0].tr('/','')
    end

    def convert_response(response)
        case @client.return_type
        when :response
            return response.response
        when :httparty
            return response
        else
            return response.parsed_response.deep_symbolize
        end
    end

  end
end
