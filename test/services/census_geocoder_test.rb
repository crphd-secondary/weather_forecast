require "test_helper"

class CensusGeocoderTest < ActiveSupport::TestCase
  test "returns every match in the Census order" do
    stub_geocode(zip_codes: [ "62701", "65801" ])

    result = CensusGeocoder.new.locate(address: "100 Main St, Springfield")

    assert result.success?
    assert_equal [ "62701", "65801" ], result.locations.map(&:zip_code)

    location = result.locations.first
    assert_equal 37.33, location.latitude
    assert_equal(-122.03, location.longitude)
    assert_equal "1 MAIN ST, SOMEWHERE, CA, 62701", location.formatted_address
  end

  test "skips matches without coordinates or zip code" do
    body = {
      "result" => {
        "addressMatches" => [
          { "matchedAddress" => "NO COORDINATES", "addressComponents" => { "zip" => "11111" } },
          { "matchedAddress" => "NO ZIP", "coordinates" => { "x" => 2.0, "y" => 1.0 }, "addressComponents" => {} },
          { "matchedAddress" => "1 MAIN ST", "coordinates" => { "x" => 2.0, "y" => 1.0 }, "addressComponents" => { "zip" => "12345" } }
        ]
      }
    }
    stub_json(ApiStubs::GEOCODE_URL, body)

    result = CensusGeocoder.new.locate(address: "1 Main St")

    assert result.success?
    assert_equal [ "1 MAIN ST" ], result.locations.map(&:formatted_address)
  end

  test "returns :no_results when the Census finds nothing" do
    stub_geocode(zip_codes: [])

    result = CensusGeocoder.new.locate(address: "nowhere")

    assert_not result.success?
    assert_equal :no_results, result.error
  end

  test "returns :request_failed when no match is usable" do
    body = { "result" => { "addressMatches" => [ { "matchedAddress" => "BROKEN" } ] } }
    stub_json(ApiStubs::GEOCODE_URL, body)

    result = CensusGeocoder.new.locate(address: "1 Main St")

    assert_not result.success?
    assert_equal :request_failed, result.error
  end

  test "returns :request_failed when the body has no address matches" do
    stub_json(ApiStubs::GEOCODE_URL, { "result" => {} })

    result = CensusGeocoder.new.locate(address: "1 Main St")

    assert_not result.success?
    assert_equal :request_failed, result.error
    assert_equal "Unexpected response body", result.message
  end

  test "returns :request_failed when the HTTP request fails" do
    stub_request(:get, ApiStubs::GEOCODE_URL).to_return(status: 500)

    result = CensusGeocoder.new.locate(address: "1 Main St")

    assert_not result.success?
    assert_equal :request_failed, result.error
    assert_equal "HTTP 500", result.message
  end

  test "returns :request_failed when the body is not JSON" do
    stub_request(:get, ApiStubs::GEOCODE_URL).to_return(status: 200, body: "<html></html>")

    result = CensusGeocoder.new.locate(address: "1 Main St")

    assert_not result.success?
    assert_equal :request_failed, result.error
  end

  test "caches successful lookups by normalized address" do
    stub = stub_geocode

    with_memory_cache do
      CensusGeocoder.new.locate(address: "1 Main St")
      result = CensusGeocoder.new.locate(address: "  1 MAIN   st ")

      assert result.success?
      assert_equal "95014", result.locations.first.zip_code
      assert_requested stub, times: 1
    end
  end

  test "does not cache failed lookups" do
    stub = stub_geocode(zip_codes: [])

    with_memory_cache do
      2.times { CensusGeocoder.new.locate(address: "nowhere") }

      assert_requested stub, times: 2
    end
  end
end
