class ForecastSearch
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :address, :string
  attribute :selected, :integer, default: ForecastService::BEST_MATCH_INDEX

  validates :address, presence: true
end
