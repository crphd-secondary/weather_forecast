require "test_helper"

class UsCensus::Geocoder::ClientTest < ActiveSupport::TestCase
  test "returns the parsed body and sends the address, benchmark and format" do
    stub = stub_request(:get, ApiStubs::GEOCODE_URL)
      .with(query: { address: "1 Main St", benchmark: "Public_AR_Current", format: "json" })
      .to_return(status: 200, body: { "result" => {} }.to_json, headers: ApiStubs::JSON_HEADERS)

    result = UsCensus::Geocoder::Client.new.geocode(address: "1 Main St")

    assert result.success?
    assert_equal({ "result" => {} }, result.body)
    assert_requested stub
  end

  test "returns a failure on HTTP errors" do
    stub_request(:get, ApiStubs::GEOCODE_URL).to_return(status: 400)

    result = UsCensus::Geocoder::Client.new.geocode(address: "1 Main St")

    assert_not result.success?
    assert_equal "HTTP 400", result.error
  end

  test "returns a failure on timeouts" do
    stub_request(:get, ApiStubs::GEOCODE_URL).to_timeout

    result = UsCensus::Geocoder::Client.new.geocode(address: "1 Main St")

    assert_not result.success?
    assert result.error.present?
  end
end
