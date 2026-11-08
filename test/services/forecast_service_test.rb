require "test_helper"

class ForecastServiceTest < ActiveSupport::TestCase
  test "returns live forecast on first request" do
    stub_geocode
    stub_forecast

    with_memory_cache do
      result = ForecastService.new.call(address: "1 Infinite Loop, Cupertino", selected_index: 0)

      assert result.success?
      assert_equal "95014", result.location.zip_code
      assert_in_delta 68.4, result.forecast.current_temperature
      assert_equal 2, result.forecast.days.size
      assert_equal 72.1, result.forecast.days.first.high
      assert_not result.cached?
    end
  end

  test "serves forecast from cache for the same zip code" do
    stub_geocode
    forecast_stub = stub_forecast

    with_memory_cache do
      ForecastService.new.call(address: "1 Infinite Loop, Cupertino", selected_index: 0)
      result = ForecastService.new.call(address: "Another street, Cupertino", selected_index: 0)

      assert result.cached?
      assert_requested forecast_stub, times: 1
    end
  end

  test "fetches again after the cache expires" do
    stub_geocode
    forecast_stub = stub_forecast

    with_memory_cache do
      ForecastService.new.call(address: "1 Infinite Loop, Cupertino", selected_index: 0)

      travel 31.minutes do
        result = ForecastService.new.call(address: "1 Infinite Loop, Cupertino", selected_index: 0)
        assert_not result.cached?
      end
      assert_requested forecast_stub, times: 2
    end
  end

  test "returns a failure when the Census finds nothing" do
    stub_geocode(zip_codes: [])

    result = ForecastService.new.call(address: "nowhere", selected_index: 0)

    assert_not result.success?
    assert_equal I18n.t("forecast_service.errors.address_not_found", address: "nowhere"), result.error
  end

  test "returns every matched address with the best match selected" do
    stub_geocode(zip_codes: [ "62701", "65801" ])
    stub_forecast

    with_memory_cache do
      result = ForecastService.new.call(address: "Springfield", selected_index: 0)

      assert_equal [ "62701", "65801" ], result.locations.map(&:zip_code)
      assert_equal 0, result.selected_index
      assert_equal "62701", result.location.zip_code
    end
  end

  test "uses the selected address for the forecast" do
    stub_geocode(zip_codes: [ "62701", "65801" ])
    stub_forecast

    with_memory_cache do
      result = ForecastService.new.call(address: "Springfield", selected_index: 1)

      assert_equal 1, result.selected_index
      assert_equal "65801", result.location.zip_code
    end
  end

  test "falls back to the best match when the selected index is out of range" do
    stub_geocode(zip_codes: [ "62701", "65801" ])
    stub_forecast

    with_memory_cache do
      assert_equal "62701", ForecastService.new.call(address: "Springfield", selected_index: 5).location.zip_code
      assert_equal "62701", ForecastService.new.call(address: "Springfield", selected_index: -1).location.zip_code
    end
  end

  test "returns a generic failure when the weather API is down" do
    stub_geocode
    stub_request(:get, ApiStubs::FORECAST_URL).to_return(status: 500)

    with_memory_cache do
      result = ForecastService.new.call(address: "1 Infinite Loop, Cupertino", selected_index: 0)

      assert_not result.success?
      assert_equal I18n.t("forecast_service.errors.generic"), result.error
    end
  end

  test "does not cache a failed weather lookup" do
    stub_geocode
    stub_request(:get, ApiStubs::FORECAST_URL)
      .to_return(status: 500)
      .then.to_return(status: 200, body: ApiStubs::FORECAST_BODY.to_json, headers: ApiStubs::JSON_HEADERS)

    with_memory_cache do
      assert_not ForecastService.new.call(address: "1 Infinite Loop, Cupertino", selected_index: 0).success?

      result = ForecastService.new.call(address: "1 Infinite Loop, Cupertino", selected_index: 0)
      assert result.success?
      assert_not result.cached?
    end
  end

  test "does not share cached forecasts between different zip codes" do
    forecast_stub = stub_forecast

    with_memory_cache do
      stub_geocode(zip_codes: [ "62701" ])
      ForecastService.new.call(address: "100 Main St, Springfield, IL", selected_index: 0)

      stub_geocode(zip_codes: [ "65801" ])
      result = ForecastService.new.call(address: "100 Main St, Springfield, MO", selected_index: 0)

      assert_not result.cached?
      assert_requested forecast_stub, times: 2
    end
  end

  test "returns a generic failure when geocoding fails" do
    stub_request(:get, ApiStubs::GEOCODE_URL).to_return(status: 500)

    result = ForecastService.new.call(address: "1 Main St", selected_index: 0)

    assert_not result.success?
    assert_equal I18n.t("forecast_service.errors.generic"), result.error
  end
end
