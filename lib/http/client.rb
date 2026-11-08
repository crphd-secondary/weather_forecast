module Http
  class Client
    TIMEOUT_SECONDS = 5

    def initialize(base_url:)
      @base_url = base_url
    end

    def get(path:, params:)
      Result.success(body: connection.get(path, params).body)
    rescue Faraday::Error => e
      Result.failure(error: error_message(e))
    end

    private

    def connection
      @connection ||= Faraday.new(url: @base_url, request: { timeout: TIMEOUT_SECONDS, open_timeout: TIMEOUT_SECONDS }) do |faraday|
        faraday.response :raise_error
        faraday.response :json
      end
    end

    def error_message(error)
      return "HTTP #{error.response_status}" if error.response_status

      error.class.name
    end
  end
end
