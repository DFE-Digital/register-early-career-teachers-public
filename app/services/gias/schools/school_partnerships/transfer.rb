module GIAS::Schools
  module SchoolPartnerships
    class Transfer
      def self.call(...) = new(...).call

      def initialize(predecessor_school_partnership:, successor_school:, author: Events::SystemAuthor.new)
        @successor_school = successor_school
        @author = author
        @predecessor_school_partnership = predecessor_school_partnership
      end

      def call
        return unless reassignment_required?

        find_or_create_school_partnership_at_successor_school!
      end

    private

      attr_reader :predecessor_school_partnership, :successor_school, :author

      def reassignment_required?
        return false if successor_school.blank?
        return false if predecessor_school_partnership.blank?

        predecessor_school != successor_school
      end

      def find_or_create_school_partnership_at_successor_school!
        ActiveRecord::Base.transaction do
          successor_school_partnership = SchoolPartnership.find_or_create_by!(
            school: successor_school,
            lead_provider_delivery_partnership:
          )

          if successor_school_partnership.previously_new_record?
            Events::Record.record_school_partnership_recreated_event!(
              author:,
              old_school_partnership: predecessor_school_partnership,
              new_school_partnership: successor_school_partnership
            )
          end

          successor_school_partnership
        end
      end

      def predecessor_school = predecessor_school_partnership.school

      delegate :lead_provider_delivery_partnership, to: :predecessor_school_partnership
    end
  end
end
