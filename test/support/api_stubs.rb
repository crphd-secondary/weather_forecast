module ApiStubs
  GEOCODE_URL = %r{\Ahttps://geocoding\.geo\.census\.gov/geocoder/locations/onelineaddress}
  FORECAST_URL = %r{\Ahttps://api\.open-meteo\.com/v1/forecast}
  JSON_HEADERS = { "Content-Type" => "application/json" }.freeze

  FORECAST_BODY = {
    "current" => { "temperature_2m" => 68.4 },
    "daily" => {
      "time" => [ "2026-11-08", "2026-11-09" ],
      "temperature_2m_max" => [ 72.1, 70.0 ],
      "temperature_2m_min" => [ 50.2, 49.8 ]
    }
  }.freeze

  def stub_geocode(zip_codes: [ "95014" ])
    matches = zip_codes.map do |zip_code|
      {
        "matchedAddress" => "1 MAIN ST, SOMEWHERE, CA, #{zip_code}",
        "coordinates" => { "x" => -122.03, "y" => 37.33 },
        "addressComponents" => { "zip" => zip_code }
      }
    end
    stub_json(GEOCODE_URL, { "result" => { "addressMatches" => matches } })
  end

  def stub_forecast(body = FORECAST_BODY)
    stub_json(FORECAST_URL, body)
  end

  def stub_json(url, body)
    stub_request(:get, url).to_return(status: 200, body: body.to_json, headers: JSON_HEADERS)
  end

  def with_memory_cache
    original = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    yield
  ensure
    Rails.cache = original
  end
end
