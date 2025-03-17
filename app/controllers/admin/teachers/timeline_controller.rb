class Admin::Teachers::TimelineController < AdminController
  def show
    @teacher = Teacher.find(params[:teacher_id])
    @events = Event.where(teacher: @teacher)
  end
end
