class Admin::Teachers::TimelineController < AdminController
  def show
    @teacher = Teacher.find(params[:teacher_id])
    @events = Events::List.new.for_teacher(@teacher)
  end
end
