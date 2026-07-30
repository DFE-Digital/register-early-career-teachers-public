module Schools
  module ChangeName
    module Confirmable
      def previous_step = :edit

      def next_step = :check_answers

      def save! = true
    end
  end
end
