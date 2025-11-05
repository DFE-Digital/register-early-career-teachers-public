module Events
  class Metadata
    class MissingAuthorError < StandardError; end
    class MissingAppropriateBodyPeriodError < StandardError; end

    private_class_method :new

    attr_reader :author, :appropriate_body_period

    def initialize(author:, appropriate_body_period:)
      @author = author
      @appropriate_body_period = appropriate_body_period
    end

    def self.with_author_but_no_appropriate_body(author:)
      fail(MissingAuthorError) if author.nil?

      new(author:, appropriate_body_period: nil)
    end

    def self.with_author_and_appropriate_body(author:, appropriate_body_period:)
      fail(MissingAuthorError) if author.nil?
      fail(MissingAppropriateBodyPeriodError) if appropriate_body_period.nil?

      new(author:, appropriate_body_period:)
    end

    def to_hash
      { author:, appropriate_body_period: }
    end
  end
end
