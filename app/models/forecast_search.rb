class ForecastSearch
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :address, :string
  attribute :selected, :integer

  validates :address, presence: true

  def selected
    super || ForecastService::BEST_MATCH_INDEX
  end
end
