module Teachers
  module Details
    class ITTDetailsComponent < ViewComponent::Base
      attr_reader :teacher

      def initialize(teacher:)
        @teacher = teacher
      end
    end
  end
end
