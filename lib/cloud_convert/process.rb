#FIXME status does not save in the initializer
#TODO Integrate the steps from the api.

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
      @client = args[:client] || CloudConvert::Client.new(processes: [self])
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
            @process_response[:subdomain] = @process_response[:url].split(".")[0].tr('/','')
        end

        return  response.response
    end

    def convert(opts)
        url = process_url(include_process_id: true)
        multi = opts[:file].respond_to?("read")
        return (send_request(http_method: :post, 
                                url: url, 
                                params: opts,
                                multi: multi) do |response|
            create_parsed_response(:conversion_response, response.parsed_response)
            @step = @conversion_response[:step].to_sym
        end).response
    end

    def status
        url = process_url(include_process_id: true)
        #puts "Status Url: #{url}"
        response = send_request(http_method: :get,
                                url: url)
        #puts "Status Response: #{response.response}"
        #puts "Status Parsed Response: #{response.parsed_response}"
        create_parsed_response(:status_response, response.parsed_response)
        @step = @status_response[:step].to_sym
        return response.response
    end

    def download(path)
        response =  HTTMultiParty.get(download_url)
        return response.parsed_response.deep_symbolize unless response.headers.content_type.start_with? 'image'
        #path = File.join(opts[:path], opts[:file])
        File.open(path, "w") do |f| 
            f.binmode # @MariusButuc's suggestion
            f.write response.parsed_response
        end
    end

    def delete
        url = construct_url(process_response[:subdomain], "process", process_response[:id])
        response = HTTMultiParty.delete(url).response
        #puts response
        return response
    end

    def list
        url = construct_url("api", "processes")
        response = HTTMultiParty.get(url, {
            body: {
                "apikey" => client.api_key
            }
            }).response
        return response
    end


    

    private

    def send_request(opts)
        puts "====== IS it multy: #{opts[:multi]}"
        opts[:params] ||= {}
        request = (opts[:multi] ? opts[:params] : opts[:params])
        response = RestClient.send(opts[:http_method], opts[:url], request)
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

    def extract_subdomain_from_url(parsed_response)
        return parsed_response[:url].split(".")[0].tr('/','')
    end

  end
end
