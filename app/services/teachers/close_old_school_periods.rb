module Teachers
  class CloseOldSchoolPeriods
    attr_reader :teacher, :new_school_start_date, :author

    def initialize(teacher:, new_school_start_date:, author:)
      @teacher = teacher
      @new_school_start_date = new_school_start_date
      @author = author
    end

    def call
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

    def periods_to_close
      teacher.ect_at_school_periods
            .where(finished_on: nil)
            .where('started_on < ?', new_school_start_date)
    end
  end
end
