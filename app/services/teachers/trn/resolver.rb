module Teachers
  module TRN
    class Resolver
      class ProposedTRNError < StandardError; end

      def initialize(teacher:, proposed_trn:)
        @teacher = teacher

        raise ProposedTRNError if @teacher.trs_response_permanent_redirect? && @teacher.trs_redirected_to.blank?
        raise ProposedTRNError if @teacher.trs_response_gone? && proposed_trn.blank?

        @proposed_trn = proposed_trn
      end

      def new_trn
        @teacher.trs_redirected_to.presence || @proposed_trn
      end
    end
  end
end
