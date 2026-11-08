require "test_helper"

class ForecastsControllerTest < ActionDispatch::IntegrationTest
  test "renders the search form on the home page" do
    get root_path

    assert_response :success
    assert_select "form[action='#{forecast_path}'] input[name=address][placeholder=?]",
                  I18n.t("forecasts.form.address_placeholder")
  end

  test "redirects to the home page with an alert when the address is blank" do
    get forecast_path, params: { address: "  " }

    assert_redirected_to root_path
    assert_equal "Address is required. Please enter a US street address.", flash[:alert]

    follow_redirect!
    assert_select ".flash.alert", "Address is required. Please enter a US street address."
  end

  test "shows the forecast and cache indicator" do
    stub_geocode
    stub_forecast

    with_memory_cache do
      get forecast_path, params: { address: "1 Infinite Loop, Cupertino" }
      assert_response :success
      assert_select ".badge.live", I18n.t("forecasts.show.live")
      assert_select ".current strong", "68°F"
      assert_select "tbody tr", 2
      assert_select "tbody tr:first-child td", "Sun, Nov 8"

      get forecast_path, params: { address: "1 Infinite Loop, Cupertino" }
      assert_select ".badge.cached", I18n.t("forecasts.show.cached")
    end
  end

  test "lists other matching addresses with the selected one preselected" do
    stub_geocode(zip_codes: [ "62701", "65801" ])
    stub_forecast

    with_memory_cache do
      get forecast_path, params: { address: "Springfield", selected: 1 }

      assert_response :success
      assert_select "h2", /65801/
      assert_select "select[name=selected] option", 2
      assert_select "select[name=selected] option[selected][value='1']"
      assert_select ".other-addresses input[type=hidden][name=address][value=Springfield]"
    end
  end

  test "hides the address list when there is a single match" do
    stub_geocode
    stub_forecast

    with_memory_cache do
      get forecast_path, params: { address: "1 Infinite Loop, Cupertino" }

      assert_select "select[name=selected]", 0
    end
  end

  test "shows an error for an unknown address" do
    stub_geocode(zip_codes: [])

    get forecast_path, params: { address: "nowhere" }

    assert_response :success
    assert_select ".error", I18n.t("forecast_service.errors.address_not_found", address: "nowhere")
  end

  test "uses the best match when the selected index is empty" do
    stub_geocode(zip_codes: [ "62701", "65801" ])
    stub_forecast

    with_memory_cache do
      get forecast_path, params: { address: "100 Main St, Springfield", selected: "" }

      assert_response :success
      assert_select "h2", /62701/
    end
  end
end
