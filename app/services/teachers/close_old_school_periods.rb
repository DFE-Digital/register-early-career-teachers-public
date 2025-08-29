module Teachers
  class CloseOldSchoolPeriods
    attr_reader :teacher, :new_school_start_date, :author

    def initialize(teacher:, new_school_start_date:, author:)
      @teacher = teacher
      @new_school_start_date = new_school_start_date.to_date
      @author = author
    end

    def call
      return unless teacher_has_existing_ect_periods?
      return unless transfer_date_has_passed?

      ActiveRecord::Base.transaction do
        periods_to_close.each do |period|
          ECTAtSchoolPeriods::Finish.new(
            ect_at_school_period: period,
            finished_on: new_school_start_date,
            author:
          ).finish!
        end
      end
    end

  private

    def teacher_has_existing_ect_periods?
      teacher.ect_at_school_periods.ongoing_on(new_school_start_date.prev_day).exists?
    end

    def transfer_date_has_passed?
      new_school_start_date <= Date.current
    end

    def periods_to_close
      @periods_to_close ||= teacher.ect_at_school_periods
                                   .ongoing_on(new_school_start_date.prev_day)
                                   .started_before(new_school_start_date)
    end
  end
end
