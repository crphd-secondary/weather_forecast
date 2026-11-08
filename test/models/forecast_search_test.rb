require "test_helper"

class ForecastSearchTest < ActiveSupport::TestCase
  test "is valid with an address" do
    assert ForecastSearch.new(address: "1600 Pennsylvania Ave NW, Washington, DC").valid?
  end

  test "requires an address" do
    search = ForecastSearch.new(address: "  ")

    assert search.invalid?
    assert_equal [ "Address is required. Please enter a US street address." ], search.errors.full_messages
  end

  test "casts the selected index to an integer" do
    assert_equal 2, ForecastSearch.new(address: "1 Main St", selected: "2").selected
  end

  test "selects the best match when no index is given" do
    assert_equal ForecastService::BEST_MATCH_INDEX, ForecastSearch.new(address: "1 Main St").selected
  end
end
