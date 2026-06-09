module GIAS::Schools
  class Replace
    attr_reader :gias_school

    def initialize(gias_school)
      @gias_school = gias_school
    end

    def replace!
      return unless gias_school.closed?
      return unless gias_school.successors.one?
      return unless gias_school.successor.open?
      return if school_already_replaced?
      return if school_is_merging? 
      return if school_is_amalgamating?

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

    def school_already_replaced?
      gias_school.successor.school.present?
    end

    def school_is_merging?
      gias_school.successor_links.where(link_type: "Successor - merged").exists?
    end

    def school_is_amalgamating?
      gias_school.successor_links.where(link_type: "Successor - amalgamated").exists?
    end

    delegate :school, to: :gias_school
  end
end
