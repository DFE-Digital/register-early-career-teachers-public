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
        school.update!(urn: gias_school.successor.urn)
        record_school_replaced_event!
      end
    end

    def record_school_replaced_event!
      Events::Record.record_school_changed_event!(
        school:,
        new_gias_school: gias_school.successor,
        old_gias_school: gias_school,
        happened_at: gias_school.successor.opened_on,
        author:
      )
    end

    def author
      Events::SystemAuthor.new
    end

    delegate :school, to: :gias_school
  end
end
