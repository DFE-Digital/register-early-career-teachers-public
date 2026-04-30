class TimeTravellersController < ApplicationController
  layout "full"

  def new
    @time_traveller = TimeTraveller.new
  end

  def create
    @time_traveller = TimeTraveller.new(**travel_to_params)

    if @time_traveller.valid?
      session[:time_travelled_date] = @time_traveller.travel_to_date.value_as_date
      redirect_to root_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:time_travelled_date] = nil
    redirect_to root_path
  end

private

  def travel_to_params
    params.expect(time_traveller: :travel_to)
  end
end
