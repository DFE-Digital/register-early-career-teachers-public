class TimeTravellersController < ApplicationController
  include MultiparameterDateErrorHandling

  layout "full"

  skip_around_action :travel_in_time

  def new
    @time_traveller = TimeTraveller.new
  end

  def create
    @time_traveller = TimeTraveller.new(**travel_to_params)

    if @time_traveller.valid?
      session["date_after_time_travel"] = @time_traveller.travel_to_date.value_as_date
      redirect_to root_path
    else
      render :new, status: :unprocessable_entity
    end
  rescue ActiveRecord::MultiparameterAssignmentErrors => e
    @time_traveller = TimeTraveller.new
    add_multiparameter_date_errors(@time_traveller, e, param_key: :time_traveller)
    render :new, status: :unprocessable_entity
  end

  def destroy
    session["date_after_time_travel"] = nil
    redirect_to root_path
  end

private

  def travel_to_params
    params.expect(time_traveller: :travel_to)
  end
end
