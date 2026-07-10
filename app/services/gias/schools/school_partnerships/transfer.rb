module GIAS::Schools
  module SchoolPartnerships
    class Transfer
      class InvalidObject < StandardError; end
      class InvalidPeriodType < StandardError; end

      attr_reader :object, :successor_school, :author

      def initialize(object:, successor_school:, author: Events::SystemAuthor.new)
        @object = object
        @successor_school = successor_school
        @author = author

        raise InvalidObject unless object.respond_to?(:school_partnership)
      end

      def self.call(**args) = new(**args).call

      def call
        return unless reassignment_required?

        find_or_create_school_partnership_at_successor_school!
      end

    private

      def reassignment_required?
        return false if successor_school.blank?
        return false if predecessor_school_partnership.blank?
        return false if period.blank?

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

      def predecessor_school_partnership = object&.school_partnership
      def predecessor_school = period.school
      def period = object.send(:mentor_at_school_period) || object.send(:ect_at_school_period)

      delegate :lead_provider_delivery_partnership, to: :predecessor_school_partnership
    end
  end
end
