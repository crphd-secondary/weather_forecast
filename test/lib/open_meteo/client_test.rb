require "test_helper"

class OpenMeteo::ClientTest < ActiveSupport::TestCase
  test "returns the parsed body and sends the forecast parameters" do
    stub = stub_request(:get, ApiStubs::FORECAST_URL)
      .with(query: hash_including(
        "latitude" => "37.33",
        "longitude" => "-122.03",
        "current" => "temperature_2m",
        "daily" => "temperature_2m_max,temperature_2m_min",
        "temperature_unit" => "fahrenheit",
        "forecast_days" => "7"
      ))
      .to_return(status: 200, body: ApiStubs::FORECAST_BODY.to_json, headers: ApiStubs::JSON_HEADERS)

    result = OpenMeteo::Client.new.forecast(latitude: 37.33, longitude: -122.03)

    assert result.success?
    assert_equal ApiStubs::FORECAST_BODY, result.body
    assert_requested stub
  end

  test "returns a failure on HTTP errors" do
    stub_request(:get, ApiStubs::FORECAST_URL).to_return(status: 400)

    result = OpenMeteo::Client.new.forecast(latitude: 37.33, longitude: -122.03)

    assert_not result.success?
    assert_equal "HTTP 400", result.error
  end

  test "returns a failure on timeouts" do
    stub_request(:get, ApiStubs::FORECAST_URL).to_timeout

    result = OpenMeteo::Client.new.forecast(latitude: 37.33, longitude: -122.03)

    assert_not result.success?
    assert result.error.present?
  end
end
