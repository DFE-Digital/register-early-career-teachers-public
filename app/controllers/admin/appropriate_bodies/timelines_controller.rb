class Admin::AppropriateBodies::TimelinesController < AdminController
  def show
    @appropriate_body = AppropriateBodyPeriod.find(params[:appropriate_body_id])
    @events = Events::List.new.for_appropriate_body_period(@appropriate_body)
  end
end
