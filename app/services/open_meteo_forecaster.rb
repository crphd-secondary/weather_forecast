class OpenMeteoForecaster
  INCOMPLETE_DATA = "Incomplete forecast data".freeze

  def forecast(latitude:, longitude:)
    response = open_meteo_client.forecast(latitude: latitude, longitude: longitude)
    return WeatherResult.failure(error: response.error) unless response.success?

    build_result(response.body)
  end

  private

  def build_result(body)
    current_temperature = body.dig("current", OpenMeteo::Client::CURRENT_TEMPERATURE_FIELD)
    daily = body["daily"]
    highs = daily[OpenMeteo::Client::DAILY_HIGH_FIELD]
    lows = daily[OpenMeteo::Client::DAILY_LOW_FIELD]
    return WeatherResult.failure(error: INCOMPLETE_DATA) unless [ current_temperature, *highs, *lows ].all?(Numeric)

    days = build_days(dates: daily["time"], highs: highs, lows: lows)
    WeatherResult.success(forecast: Forecast.new(current_temperature: current_temperature, days: days))
  end

  def build_days(dates:, highs:, lows:)
    dates.zip(highs, lows).map do |date, high, low|
      Day.new(date: Date.iso8601(date), high: high, low: low)
    end
  end

  def open_meteo_client
    @open_meteo_client ||= OpenMeteo::Client.new
  end
end
