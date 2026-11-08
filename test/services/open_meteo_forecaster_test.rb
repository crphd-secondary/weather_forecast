require "test_helper"

class OpenMeteoForecasterTest < ActiveSupport::TestCase
  test "builds the current temperature and daily highs and lows" do
    stub_forecast

    result = OpenMeteoForecaster.new.forecast(latitude: 37.33, longitude: -122.03)

    assert result.success?
    assert_equal 68.4, result.forecast.current_temperature
    assert_equal [ Date.new(2026, 11, 8), Date.new(2026, 11, 9) ], result.forecast.days.map(&:date)
    assert_equal [ 72.1, 70.0 ], result.forecast.days.map(&:high)
    assert_equal [ 50.2, 49.8 ], result.forecast.days.map(&:low)
  end

  test "returns a failure when the HTTP request fails" do
    stub_request(:get, ApiStubs::FORECAST_URL).to_return(status: 500)

    result = OpenMeteoForecaster.new.forecast(latitude: 37.33, longitude: -122.03)

    assert_not result.success?
    assert_equal "HTTP 500", result.error
  end

  test "returns a failure when the current temperature is null" do
    body = ApiStubs::FORECAST_BODY.deep_dup
    body["current"]["temperature_2m"] = nil
    stub_forecast(body)

    result = OpenMeteoForecaster.new.forecast(latitude: 37.33, longitude: -122.03)

    assert_not result.success?
    assert_equal "Incomplete forecast data", result.error
  end

  test "returns a failure when a daily temperature is null" do
    body = ApiStubs::FORECAST_BODY.deep_dup
    body["daily"]["temperature_2m_max"] = [ 72.1, nil ]
    stub_forecast(body)

    result = OpenMeteoForecaster.new.forecast(latitude: 37.33, longitude: -122.03)

    assert_not result.success?
    assert_equal "Incomplete forecast data", result.error
  end

  test "round-trips a forecast through a plain hash" do
    stub_forecast
    forecast = OpenMeteoForecaster.new.forecast(latitude: 37.33, longitude: -122.03).forecast

    assert_equal forecast, OpenMeteoForecaster::Forecast.from_h(forecast.to_h)
    assert_kind_of Hash, forecast.to_h[:days].first
  end
end
