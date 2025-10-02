module Rules
  class Base
    def initialize(subject)
      @subject = subject
    end

    def show_row_in_check_your_answers?
      raise NotImplementedError, "#{self.class} must implement #show_row_in_check_your_answers?"
    end

  private

    attr_reader :subject
  end
end
