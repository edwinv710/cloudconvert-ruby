##
# Client  handles all the information needed to connect to the api. 


# TODO research other wrappers to see how they handle the client without an api key. Do they allow the creating of the client with out one?
# TODO Build 'running_conversions' method.
# TODO Build 'conversion_types' method.
# TODO Inspect the initialize to see if I should add or remove options. Parameters vs hash.


module CloudConvert
  class Client
    include HTTMultiParty
    ##
    # The api key obtained from the cloud convert service.
    attr_reader :api_key
    ##
    # An array containing references to the processes created through the client.
    attr_reader :processes
    attr_accessor :return_type

    ##
    # Creates a new client with an api key. Optionally, you can also pass an array of processes.
    def initialize(args = {})
      @api_key = args[:api_key]
      args[:processes].nil? ?
        @processes = [] :
        @processes = args[:processes]
      @return_type = args[:return_type] || :json
    end

    ##
    # Builds a process object and adds it to the client. Accepts the input format and output format for the conversion.
    def build_process(opts = {})
      opts[:client] = self
      process = CloudConvert::Process.new(opts)
      processes.push(process)
      return process
    end    

    ##
    # Returns an array of hash with the results from the Cloud Convert list endpoint.
    def list
        url = "#{CloudConvert::PROTOCOL}://api.#{CloudConvert::DOMAIN}/processes"
        response = CloudConvert::Client.send(:get, url, {query: {apikey: self.api_key}})
        return convert_response response
    end  

    private

    def convert_response(response)
      return response.response if self.return_type == :response
      return response.parsed_response.deep_symbolize
    end

  end
end
