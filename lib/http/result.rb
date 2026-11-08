module Http
  class Result
    attr_reader :body, :error

    def self.success(body:)
      new(body: body, error: nil)
    end

    def self.failure(error:)
      new(body: nil, error: error)
    end

    def initialize(body:, error:)
      @body = body
      @error = error
    end

    def success?
      error.nil?
    end
  end
end
