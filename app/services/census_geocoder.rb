class CensusGeocoder
  CACHE_TTL = 1.day

  def locate(address:)
    cached_locations = Rails.cache.read(cache_key(address))
    return build_cached_result(cached_locations) if cached_locations

    result = fetch_locations(address)
    Rails.cache.write(cache_key(address), result.locations.map(&:to_h), expires_in: CACHE_TTL) if result.success?
    result
  end

  private

  def fetch_locations(address)
    response = geocoder_client.geocode(address: address)
    return build_failed_result(response.error) unless response.success?

    matches = response.body.dig("result", "addressMatches")
    return build_no_result_result if matches.empty?

    GeocodeResult.success(locations: matches.map { |match| build_location(match) })
  end

  def build_location(match)
    Location.new(
      latitude: match.dig("coordinates", "y"),
      longitude: match.dig("coordinates", "x"),
      zip_code: match.dig("addressComponents", "zip"),
      formatted_address: match["matchedAddress"]
    )
  end

  def build_cached_result(cached_locations)
    GeocodeResult.success(locations: cached_locations.map { |attributes| Location.new(**attributes) })
  end

  def build_no_result_result
    GeocodeResult.failure(error: :no_results, message: nil)
  end

  def build_failed_result(message)
    GeocodeResult.failure(error: :request_failed, message: message)
  end

  def cache_key(address)
    "geocode/v2/#{Digest::SHA256.hexdigest(address.squish.downcase)}"
  end

  def geocoder_client
    @geocoder_client ||= UsCensus::Geocoder::Client.new
  end
end
