module Admin
  module TeachingSchoolHubs
    class SummaryCardComponent < ApplicationComponent
      with_collection_parameter :teaching_school_hub

      attr_reader :teaching_school_hub

      delegate :appropriate_body_periods, :name, to: :teaching_school_hub

      # @param teaching_school_hub [TeachingSchoolHub]
      def initialize(teaching_school_hub:)
        @teaching_school_hub = teaching_school_hub
      end

      # @return [Array<AppropriateBodyPeriod>]
      def periods = appropriate_body_periods.sort_by { it.display_name.to_s }
    end
  end
end
