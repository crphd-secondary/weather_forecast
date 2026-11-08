class OpenMeteoForecaster
  Forecast = Data.define(:current_temperature, :days) do
    def self.from_h(attributes)
      new(current_temperature: attributes[:current_temperature], days: attributes[:days].map { |day| Day.new(**day) })
    end

    def to_h
      { current_temperature: current_temperature, days: days.map(&:to_h) }
    end
  end
end
