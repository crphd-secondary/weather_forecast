class OpenMeteoForecaster
  class WeatherResult
    attr_reader :forecast, :error

    def self.success(forecast:)
      new(forecast: forecast, error: nil)
    end

    def self.failure(error:)
      new(forecast: nil, error: error)
    end

    def initialize(forecast:, error:)
      @forecast = forecast
      @error = error
    end

    def success?
      error.nil?
    end
  end
end
