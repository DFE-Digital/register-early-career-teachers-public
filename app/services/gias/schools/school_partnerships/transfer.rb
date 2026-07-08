module GIAS::Schools
  module SchoolPartnerships
    class Transfer
      class InvalidObject < StandardError; end
      class InvalidPeriodType < StandardError; end

      attr_reader :object, :target_school, :period_type, :author

      PERIOD_TYPES = %i[mentor_at_school_period ect_at_school_period].freeze

      def initialize(object:, target_school:, period_type:, author: Events::SystemAuthor.new)
        @object = object
        @target_school = target_school
        @author = author
        @period_type = period_type

        raise InvalidObject unless object.respond_to?(:school_partnership)
        raise InvalidPeriodType unless PERIOD_TYPES.include?(period_type)
        raise InvalidPeriodType unless object.respond_to?(period_type)
      end

      def self.call(...) = new(...).call

      def call
        return unless reassignment_required?

        create_school_partnership_at_target_school!
      end

    private

      def reassignment_required?
        return false unless target_school.present?
        return false unless source_school_partnership.present?
        return false unless period.present?

        source_school != target_school
      end

      def create_school_partnership_at_target_school!
        ActiveRecord::Base.transaction do
          target_school_partnership = SchoolPartnership.find_or_create_by!(
            school: target_school,
            lead_provider_delivery_partnership:
          )

          if target_school_partnership.previously_new_record?
            Events::Record.record_school_partnership_recreated_event!(
              author:,
              old_school_partnership: source_school_partnership,
              new_school_partnership: target_school_partnership
            )
          end

          target_school_partnership
        end
      end

      def source_school_partnership = object&.school_partnership
      def source_school = period.school
      def period = object.send(period_type)

      delegate :lead_provider_delivery_partnership, to: :source_school_partnership

    end
  end
end
