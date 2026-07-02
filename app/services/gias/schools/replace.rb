module GIAS::Schools
  class Replace
    attr_reader :gias_school

    def initialize(gias_school)
      @gias_school = gias_school
    end

    def replace!
      return false unless gias_school.can_be_replaced?

      replace_school!

      true
    end

  private

    def replace_school!
      ActiveRecord::Base.transaction do
        ect_at_school_periods_to_be_moved =
          school.ect_at_school_periods.includes(:teacher).load

        mentor_at_school_periods_to_be_moved =
          school.mentor_at_school_periods.includes(:teacher).load

        old_school_name = Schools::Name.new(school).name_and_urn

        school.update!(urn: successor.urn)
        record_school_replaced_event!

        record_ect_moved_to_new_school_event!(ect_at_school_periods_to_be_moved, old_school_name)
        record_mentor_moved_to_new_school_event!(mentor_at_school_periods_to_be_moved, old_school_name)
      end
    end

    def record_ect_moved_to_new_school_event!(periods, old_school_name)
      periods.each do |ect_at_school_period|
        Events::Record.record_teacher_ect_at_school_period_moved_school!(
          teacher: ect_at_school_period.teacher,
          ect_at_school_period:,
          new_school: successor.school,
          old_school_name:,
          happened_at: successor.opened_on,
          author:
        )
      end
    end

    def record_mentor_moved_to_new_school_event!(periods, old_school_name)
      periods.each do |mentor_at_school_period|
        Events::Record.record_teacher_mentor_at_school_period_moved_school!(
          teacher: mentor_at_school_period.teacher,
          mentor_at_school_period:,
          new_school: successor.school,
          old_school_name:,
          happened_at: successor.opened_on,
          author:
        )
      end
    end

    def record_school_replaced_event!
      Events::Record.record_school_changed_event!(
        school:,
        new_gias_school: successor,
        old_gias_school: gias_school,
        happened_at: successor.opened_on,
        author:
      )
    end

    def author
      Events::SystemAuthor.new
    end

    def new_school = successor.school

    delegate :successor, to: :gias_school
    delegate :school, to: :gias_school
  end
end
