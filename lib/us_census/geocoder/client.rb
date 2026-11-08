module UsCensus
  module Geocoder
    class Client
      PATH = "/geocoder/locations/onelineaddress".freeze
      CURRENT_ADDRESS_DATA = "Public_AR_Current".freeze
      JSON_FORMAT = "json".freeze

      def geocode(address:)
        http_client.get(
          path: PATH,
          params: { address: address, benchmark: CURRENT_ADDRESS_DATA, format: JSON_FORMAT }
        )
      end

      private

      def http_client
        @http_client ||= Http::Client.new(base_url: config.base_url)
      end

      def config
        Rails.configuration.x.census_geocoder
      end
    end
  end
end
