module TrainingPeriods
  class Finish
    attr_reader :training_period,
      :finished_on,
      :author,
      :ect_at_school_period,
      :mentor_at_school_period,
      :teacher,
      :school

    private_class_method :new

    def initialize(training_period:, finished_on:, author:, ect_at_school_period:, mentor_at_school_period:, teacher:, school:)
      @training_period = training_period
      @finished_on = finished_on
      @author = author

      @ect_at_school_period = ect_at_school_period
      @mentor_at_school_period = mentor_at_school_period

      @teacher = teacher
      @school = school
    end

    def self.ect_training(training_period:, ect_at_school_period:, finished_on:, author:)
      school = ect_at_school_period.school
      teacher = ect_at_school_period.teacher

      new(mentor_at_school_period: nil, training_period:, ect_at_school_period:, teacher:, school:, finished_on:, author:)
    end

    def self.mentor_training(training_period:, mentor_at_school_period:, finished_on:, author:)
      school = mentor_at_school_period.school
      teacher = mentor_at_school_period.teacher

      new(ect_at_school_period: nil, training_period:, mentor_at_school_period:, teacher:, school:, finished_on:, author:)
    end

    def finish!
      ActiveRecord::Base.transaction do
        training_period.update!(finished_on:)

        Events::Record.record_teacher_finishes_training_period_event!(
          author:,
          school:,
          happened_at: finished_on,
          ect_at_school_period:,
          mentor_at_school_period:,
          training_period:,
          teacher:
        )
      end
    end
  end
end
