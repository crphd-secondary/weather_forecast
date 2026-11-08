class ForecastService
  class ForecastResult
    attr_reader :locations, :selected_index, :forecast, :fetched_at, :error

    def self.success(locations:, selected_index:, forecast:, fetched_at:, cached:)
      new(locations: locations, selected_index: selected_index, forecast: forecast,
          fetched_at: fetched_at, cached: cached, error: nil)
    end

    def self.failure(error:)
      new(locations: [], selected_index: nil, forecast: nil, fetched_at: nil, cached: false, error: error)
    end

    def initialize(locations:, selected_index:, forecast:, fetched_at:, cached:, error:)
      @locations = locations
      @selected_index = selected_index
      @forecast = forecast
      @fetched_at = fetched_at
      @cached = cached
      @error = error
    end

    def location
      return nil if selected_index.nil?

      locations[selected_index]
    end

    def success?
      error.nil?
    end

    def cached?
      @cached
    end
  end
end
