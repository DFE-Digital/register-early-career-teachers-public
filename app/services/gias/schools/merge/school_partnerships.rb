module GIAS::Schools
  module Merge
    class SchoolPartnerships
      class SameSchoolError < StandardError; end
      attr_reader :existing_school_partnership, :school_without_partnership, :author

      def initialize(existing_school_partnership:, school_without_partnership:, author: Events::SystemAuthor.new)
        @existing_school_partnership = existing_school_partnership
        @school_without_partnership = school_without_partnership
        @author = author
      end

      def self.resolve(...) = new(...).resolve!

      def resolve!
        return unless existing_school_partnership
        return unless school_without_partnership
        raise SameSchoolError if existing_school_partnership.school == school_without_partnership

        ActiveRecord::Base.transaction do
          new_school_partnership = SchoolPartnership.find_or_create_by!(
            school: school_without_partnership,
            lead_provider_delivery_partnership:
          )

          if new_school_partnership.previously_new_record?
            Events::Record.record_school_partnership_recreated_event!(
              author:,
              old_school_partnership: existing_school_partnership,
              new_school_partnership:
            )
          end

          new_school_partnership
        end
      end

      delegate :lead_provider_delivery_partnership, to: :existing_school_partnership
    end
  end
end
