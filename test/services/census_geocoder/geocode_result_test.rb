require "test_helper"

class CensusGeocoder::GeocodeResultTest < ActiveSupport::TestCase
  test "success carries the locations" do
    result = CensusGeocoder::GeocodeResult.success(locations: [ :location ])

    assert result.success?
    assert_equal [ :location ], result.locations
  end

  test "failure carries the reason and message" do
    result = CensusGeocoder::GeocodeResult.failure(error: :request_failed, message: "timeout")

    assert_not result.success?
    assert_equal :request_failed, result.error
    assert_equal "timeout", result.message
    assert_empty result.locations
  end
end
