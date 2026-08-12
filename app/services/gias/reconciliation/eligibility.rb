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
        successors.empty? &&
        not_a_predecessor?
    end

    def can_be_opened?
      open_status? &&
        school.blank? &&
        no_predecessors? &&
        not_a_successor? &&
        successors.empty? &&
        not_a_predecessor?
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

    def no_predecessors?
      !gias_school.predecessors.exists?
    end

    def not_a_successor?
      !GIAS::SchoolLink.where(to_gias_school: gias_school, link_type: GIAS::SchoolLink::SUCCESSOR_LINK_TYPES).exists?
    end

    def not_a_predecessor?
      !GIAS::SchoolLink.where(to_gias_school: gias_school, link_type: GIAS::SchoolLink::PREDECESSOR_LINK_TYPES).exists?
    end

    delegate :school, :closed_on, :closed_status?, :open_status?, to: :gias_school
  end
end
