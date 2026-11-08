module OpenMeteo
  class Client
    PATH = "/v1/forecast".freeze
    FORECAST_DAYS = 7
    CURRENT_TEMPERATURE_FIELD = "temperature_2m".freeze
    DAILY_HIGH_FIELD = "temperature_2m_max".freeze
    DAILY_LOW_FIELD = "temperature_2m_min".freeze
    TEMPERATURE_UNIT = "fahrenheit".freeze
    LOCAL_TIMEZONE = "auto".freeze

    def forecast(latitude:, longitude:)
      http_client.get(
        path: PATH,
        params: {
          latitude: latitude,
          longitude: longitude,
          current: CURRENT_TEMPERATURE_FIELD,
          daily: "#{DAILY_HIGH_FIELD},#{DAILY_LOW_FIELD}",
          temperature_unit: TEMPERATURE_UNIT,
          timezone: LOCAL_TIMEZONE,
          forecast_days: FORECAST_DAYS
        }
      )
    end

    private

    def http_client
      @http_client ||= Http::Client.new(base_url: config.base_url)
    end

    def config
      Rails.configuration.x.open_meteo
    end
  end
end
