require "application_system_test_case"

class ForecastsTest < ApplicationSystemTestCase
  test "searching an address and switching to another match" do
    stub_geocode(zip_codes: [ "62701", "65801" ])
    stub_forecast

    visit root_path
    fill_in I18n.t("forecasts.form.address_label"), with: "100 Main St, Springfield"
    click_on I18n.t("forecasts.form.submit")

    assert_selector "h2", text: "62701"
    assert_selector ".badge.live"
    assert_selector ".current strong", text: "68°F"

    select "1 MAIN ST, SOMEWHERE, CA, 65801", from: I18n.t("forecasts.show.other_addresses")

    assert_selector "h2", text: "65801"
    assert_current_path(/selected=1/)
  end

  test "showing the cached badge when the same zip code is searched again" do
    stub_geocode
    stub_forecast

    with_memory_cache do
      visit forecast_path(address: "1 Main St, Somewhere, CA")
      assert_selector ".badge.live"

      visit forecast_path(address: "1 Main St, Somewhere, CA")
      assert_selector ".badge.cached"
    end
  end
end
