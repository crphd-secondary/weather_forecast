class CensusGeocoder
  class GeocodeResult
    attr_reader :locations, :error, :message

    def self.success(locations:)
      new(locations: locations, error: nil, message: nil)
    end

    def self.failure(error:, message:)
      new(locations: [], error: error, message: message)
    end

    def initialize(locations:, error:, message:)
      @locations = locations
      @error = error
      @message = message
    end

    def success?
      error.nil?
    end
  end
end
