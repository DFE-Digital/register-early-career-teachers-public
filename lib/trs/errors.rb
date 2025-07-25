module TRS
  module Errors
    class TeacherNotFound < StandardError; end
    class APIRequestError < StandardError; end
    class TeacherDeactivated < StandardError; end
    class QTSNotAwarded < StandardError; end
    class ProhibitedFromTeaching < StandardError; end
    class InductionAlreadyCompleted < StandardError; end
  end
end
