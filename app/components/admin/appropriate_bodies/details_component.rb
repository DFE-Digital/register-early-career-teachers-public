module Admin
  module AppropriateBodies
    class DetailsComponent < ApplicationComponent
      attr_reader :appropriate_body

      # @param appropriate_body [AppropriateBody]
      def initialize(appropriate_body:)
        @appropriate_body = appropriate_body
      end

      # @return [Boolean]
      def current_ects?
        current_ect_count.positive?
      end

      # @return [Integer]
      def current_ect_count
        ::Teachers::Search.new(appropriate_bodies: appropriate_body).search.count
      end

      # @return [Boolean]
      def bulk_uploads?
        bulk_upload_count.positive?
      end

      # @return [Integer]
      def bulk_upload_count
        ::PendingInductionSubmissionBatch.for_appropriate_body(appropriate_body).count
      end
    end
  end
end
