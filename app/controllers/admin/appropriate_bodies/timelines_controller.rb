class Admin::AppropriateBodies::TimelinesController < AdminController
  def show
    @appropriate_body = AppropriateBody.find(params[:appropriate_body_id])
    @events = Events::List.new.for_appropriate_body(@appropriate_body)
  end
end
