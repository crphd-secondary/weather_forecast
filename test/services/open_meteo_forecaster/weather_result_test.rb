require "test_helper"

class OpenMeteoForecaster::WeatherResultTest < ActiveSupport::TestCase
  test "success carries the forecast" do
    result = OpenMeteoForecaster::WeatherResult.success(forecast: :forecast)

    assert result.success?
    assert_equal :forecast, result.forecast
  end

  test "failure carries the error" do
    result = OpenMeteoForecaster::WeatherResult.failure(error: "boom")

    assert_not result.success?
    assert_equal "boom", result.error
    assert_nil result.forecast
  end
end
