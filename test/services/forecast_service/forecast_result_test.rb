require "test_helper"

class ForecastService::ForecastResultTest < ActiveSupport::TestCase
  test "success exposes the selected location" do
    locations = [ :first, :second ]
    result = ForecastService::ForecastResult.success(
      locations: locations, selected_index: 1, forecast: :forecast, fetched_at: Time.current, cached: true
    )

    assert result.success?
    assert result.cached?
    assert_equal :second, result.location
  end

  test "failure carries the error message" do
    result = ForecastService::ForecastResult.failure(error: "Oops")

    assert_not result.success?
    assert_not result.cached?
    assert_equal "Oops", result.error
    assert_nil result.location
  end
end
