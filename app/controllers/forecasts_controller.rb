class ForecastsController < ApplicationController
  def new
  end

  def show
    @search = ForecastSearch.new(forecast_params)
    return redirect_to(root_path, alert: @search.errors.full_messages.to_sentence) if @search.invalid?

    @result = ForecastService.new.call(address: @search.address, selected_index: @search.selected)
  end

  private

  def forecast_params
    params.permit(:address, :selected)
  end
end
