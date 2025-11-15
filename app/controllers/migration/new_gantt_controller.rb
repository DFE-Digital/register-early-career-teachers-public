module Migration
  class NewGanttController < AdminController
    def show
      send_data(Migration::PostMigrationGantt.new(ect_at_school_periods:, mentor_at_school_periods:).to_png, type: "image/png")
    end

  private

    def teacher
      @teacher ||= Teacher.find(params[:teacher_id])
    end

    def ect_at_school_periods
      teacher.ect_at_school_periods
    end

    def mentor_at_school_periods
      teacher.mentor_at_school_periods
    end
  end
end
