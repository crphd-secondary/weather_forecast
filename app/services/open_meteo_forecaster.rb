class OpenMeteoForecaster
  INCOMPLETE_DATA = "Incomplete forecast data".freeze

  def forecast(latitude:, longitude:)
    response = open_meteo_client.forecast(latitude: latitude, longitude: longitude)
    return WeatherResult.failure(error: response.error) unless response.success?

    build_result(response.body)
  end

  private

  def build_result(body)
    return WeatherResult.failure(error: "Unexpected response body") unless body.is_a?(Hash)

    current_temperature = body.dig("current", OpenMeteo::Client::CURRENT_TEMPERATURE_FIELD)
    daily = body["daily"]
    return WeatherResult.failure(error: INCOMPLETE_DATA) unless current_temperature.is_a?(Numeric) && daily.is_a?(Hash)

    days = build_days(
      dates: daily["time"],
      highs: daily[OpenMeteo::Client::DAILY_HIGH_FIELD],
      lows: daily[OpenMeteo::Client::DAILY_LOW_FIELD]
    )
    return WeatherResult.failure(error: INCOMPLETE_DATA) if days.nil?

    WeatherResult.success(forecast: Forecast.new(current_temperature: current_temperature, days: days))
  end

  def build_days(dates:, highs:, lows:)
    return nil unless valid_daily_series?(dates: dates, highs: highs, lows: lows)

    days = dates.zip(highs, lows).map do |date, high, low|
      Day.new(date: parse_date(date), high: high, low: low)
    end
    days.any? { |day| day.date.nil? } ? nil : days
  end

  def valid_daily_series?(dates:, highs:, lows:)
    return false unless [ dates, highs, lows ].all?(Array)
    return false unless highs.size == dates.size && lows.size == dates.size

    (highs + lows).all?(Numeric)
  end

  def parse_date(value)
    Date.iso8601(value.to_s)
  rescue Date::Error
    nil
  end

  def open_meteo_client
    @open_meteo_client ||= OpenMeteo::Client.new
  end
end
