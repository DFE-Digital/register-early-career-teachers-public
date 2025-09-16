module TRS
  module Errors
    class APIRequestError < StandardError; end
    class InductionAlreadyCompleted < StandardError; end
    class ProhibitedFromTeaching < StandardError; end
    class QTSNotAwarded < StandardError; end
    class TeacherDeactivated < StandardError; end
    class TeacherNotFound < StandardError; end
  end
end
