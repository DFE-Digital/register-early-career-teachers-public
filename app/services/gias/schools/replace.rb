module GIAS::Schools
  class Replace
    attr_reader :gias_school

    def initialize(gias_school)
      @gias_school = gias_school
    end

    def self.call
      GIAS::School.includes(:school).joins(:school).replaceable.find_each do |gias_school|
        new(gias_school).replace!
      end
    end

    def replace!
      return unless gias_school.closed?
      return unless gias_school.successors.one?
      return unless gias_school.successor.open?
      return if already_replaced?

      ActiveRecord::Base.transaction do
        replace_school!
        record_school_replaced_event!
      end
    end

  private

    def replace_school!
      school.update!(urn: gias_school.successor.urn)
    end

    def record_school_replaced_event!
      Schools::Events::SchoolReplaced.create!(
        school:,
        successor_gias_school: gias_school.successor,
        previous_gias_school: gias_school,
        successor_urn: gias_school.successor.urn,
        previous_urn: gias_school.urn,
        author:
      )
    end

    def author
      @author ||= Events::SystemAuthor.new
    end

    def already_replaced?
      gias_school.successor.school.present?
    end

    delegate :school, to: :gias_school
  end
end
