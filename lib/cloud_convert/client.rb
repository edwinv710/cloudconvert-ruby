# TODO research other wrappers to see how they handle the client without an api key. Do they allow the creating of the client with out one?
# TODO Build 'running_conversions' method.
# TODO Build 'conversion_types' method.
# TODO Inspect the initialize to see if I should add or remove options. Parameters vs hash.

module CloudConvert
  class Client

    attr_reader :api_key, :processes

    def initialize(args = {})
      @api_key = args[:api_key]
      args[:processes].nil? ?
        @processes = [] :
        @processes = args[:processes]
    end

    def build_process(opts = {})
      opts[:client] = self
      process = CloudConvert::Process.new(opts)
      processes.push(process)
      return process
    end

    def set_api_key(api_key)
      @api_key = api_key
    end

  end
end
