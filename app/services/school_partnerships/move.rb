module SchoolPartnerships
  class Move
    class SameSchoolError < StandardError; end
    attr_reader :school_partnership, :school, :author

    def initialize(school_partnership:, school:, author: Events::SystemAuthor.new)
      @school_partnership = school_partnership
      @school = school
      @author = author
    end

    def call
      return unless school_partnership
      return unless school
      raise SameSchoolError if school_partnership.school == school

      ActiveRecord::Base.transaction do
        new_school_partnership = SchoolPartnership.find_or_create_by(
            school:,
            lead_provider_delivery_partnership:
          )

        if new_school_partnership.previously_new_record?
          Events::Record.record_school_partnership_moved_event!(
            author:,
            old_school_partnership: school_partnership,
            new_school_partnership:,
            happened_at: Time.current
          )
        end

        new_school_partnership
      end
    end
    private
    delegate :lead_provider_delivery_partnership, to: :school_partnership
  end
end
