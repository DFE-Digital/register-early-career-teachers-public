module Schools
  class Replace
    attr_reader :school

    def initialize(school)
      @school = school
    end

    def self.call
      GIAS::School.includes(:school).joins(:school).closed_status.with_successors.without_schools.find_each do |gias_school|
        new(gias_school.school).replace!
      end
    end

    def replace!
      return unless gias_school.closed?
      return unless gias_school.successors.one?
      return unless gias_school.successor.open?
      return if already_replaced?

      replace_school!
      
      record_school_replaced_event!
    end

    private

    def replace_school!
      school.update!(urn: successor_gias_school.urn)
    end

    def record_school_replaced_event!
      Schools::Events::SchoolReplaced.create!(
        school: ,
        successor_gias_school: successor_gias_school,
        previous_gias_school: gias_school,
        successor_urn: successor_gias_school.urn,
        previous_urn: gias_school.urn,  
        author:,
      )
    end

    def author
      @author ||= Events::SystemAuthor.new
    end

    def already_replaced?
      gias_school.successor.school.present?
    end

    delegate :gias_school, to: :school
    delegate :successor, to: :gias_school, prefix: true
  end
end
