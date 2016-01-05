# TODO research other wrappers to see how they handle the client without an api key. Do they allow the creating of the client with out one?
# TODO Build 'running_conversions' method.
# TODO Build 'conversion_types' method.
# TODO Inspect the initialize to see if I should add or remove options. Parameters vs hash.

module CloudConvert
  class Client
    include HTTMultiParty
    attr_reader :api_key, :processes
    attr_accessor :return_type

    def initialize(args = {})
      @api_key = args[:api_key]
      args[:processes].nil? ?
        @processes = [] :
        @processes = args[:processes]
      @return_type = args[:return_type] || :json
    end

    def build_process(opts = {})
      opts[:client] = self
      process = CloudConvert::Process.new(opts)
      processes.push(process)
      return process
    end

    def list
        url = "#{CloudConvert::PROTOCOL}://api.#{CloudConvert::DOMAIN}/processes"
        response = CloudConvert::Client.send(:get, url, query: {apikey: self.api_key})
        return convert_response response
    end  

    private

    def convert_response(response)
      return response.response if self.return_type == :response
      return response.parsed_response.deep_symbolize
    end

  end
end
