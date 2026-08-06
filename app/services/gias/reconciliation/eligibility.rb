module GIAS::Reconciliation
  class Eligibility
    def initialize(gias_school)
      @gias_school = gias_school
    end

    def can_be_closed?
      closed_status? &&
        closed_on_or_before_today? &&
        school.present? &&
        !school_closed_event_recorded? &&
        successors.empty?
    end

    def can_be_opened?
      open_status? &&
        school.blank? &&
        predecessors.empty? &&
        successors.empty?
    end

    def can_be_replaced?
      closed_status? &&
        closed_on_or_before_today? &&
        school.present? &&
        school_being_replaced? &&
        has_one_open_successor? &&
        successor.school.blank?
    end

    def can_be_merged?
      closed_status? &&
        closed_on_or_before_today? &&
        school.present? &&
        school_being_merged_or_amalgamated? &&
        !school_merged_event_recorded? &&
        has_one_open_successor? &&
        successor.school.present?
    end

  private

    attr_reader :gias_school

    def closed_on_or_before_today?
      return false if closed_on.blank?

      closed_on <= Date.current
    end

    def school_merged_event_recorded?
      Event.where(school:, event_type: :school_merged).exists?
    end

    def school_closed_event_recorded?
      Event.where(school:, event_type: :school_closed).exists?
    end

    def school_being_merged_or_amalgamated?
      gias_school.successor_links.where(
        link_type: [GIAS::SchoolLink::SUCCESSOR_MERGED, GIAS::SchoolLink::SUCCESSOR_AMALGAMATED]
      ).exists?
    end

    def school_being_replaced?
      gias_school.successor_links.where(link_type: GIAS::SchoolLink::SUCCESSOR).exists?
    end

    def has_one_open_successor?
      successors.one? && successor.open_status?
    end

    def successors
      @successors ||= gias_school.successors.take(2)
    end

    def successor
      successors.first
    end

    delegate :school, :predecessors, :closed_on, :closed_status?, :open_status?, to: :gias_school
  end
end
