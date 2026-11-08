class ForecastService
  CACHE_TTL = 30.minutes
  BEST_MATCH_INDEX = 0

  def call(address:, selected_index:)
    geocode = CensusGeocoder.new.locate(address: address)
    return geocode_failure(geocode: geocode, address: address) unless geocode.success?

    selected_index = valid_location_index(locations: geocode.locations, requested_index: selected_index)
    location = geocode.locations[selected_index]
    cache_key = cache_key(location)

    cached_entry = Rails.cache.read(cache_key)
    if cached_entry
      return build_success(locations: geocode.locations, selected_index: selected_index, entry: cached_entry, cached: true)
    end

    weather = OpenMeteoForecaster.new.forecast(latitude: location.latitude, longitude: location.longitude)
    return weather_failure(weather) unless weather.success?

    entry = { forecast: weather.forecast.to_h, fetched_at: Time.current }
    Rails.cache.write(cache_key, entry, expires_in: CACHE_TTL)
    build_success(locations: geocode.locations, selected_index: selected_index, entry: entry, cached: false)
  end

  private

  def valid_location_index(locations:, requested_index:)
    return requested_index if requested_index.between?(0, locations.size - 1)

    BEST_MATCH_INDEX
  end

  def build_success(locations:, selected_index:, entry:, cached:)
    ForecastResult.success(
      locations: locations,
      selected_index: selected_index,
      forecast: OpenMeteoForecaster::Forecast.from_h(entry[:forecast]),
      fetched_at: entry[:fetched_at],
      cached: cached
    )
  end

  def geocode_failure(geocode:, address:)
    case geocode.error
    when :no_results
      ForecastResult.failure(error: error_message(:address_not_found, address: address))
    else
      Rails.logger.error("[ForecastService] Geocoding failed: #{geocode.message}")
      ForecastResult.failure(error: error_message(:generic))
    end
  end

  def weather_failure(weather)
    Rails.logger.error("[ForecastService] Weather lookup failed: #{weather.error}")
    ForecastResult.failure(error: error_message(:generic))
  end

  def error_message(key, **params)
    I18n.t(key, scope: "forecast_service.errors", **params)
  end

  def cache_key(location)
    "forecast/v3/#{location.zip_code}"
  end
end
