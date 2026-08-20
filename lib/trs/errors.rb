module TRS
  module Errors
    class APIRequestError < StandardError; end
    class InductionAlreadyCompleted < StandardError; end
    class ProhibitedFromTeaching < StandardError; end
    class QTSNotAwarded < StandardError; end
    class TeacherDeactivated < StandardError; end
    class TeacherNotFound < StandardError; end

    class TeacherMerged < StandardError
      attr_reader :trn, :redirected_to

      def initialize(trn:, redirected_to:)
        @trn = trn
        @redirected_to = redirected_to

        super("TRN #{trn} redirects to TRN #{redirected_to}")
      end
    end
  end
end
