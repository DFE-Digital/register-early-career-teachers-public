module Events
  class Metadata
    class MissingAuthorError < StandardError; end
    class MissingAppropriateBodyError < StandardError; end

    private_class_method :new

    attr_reader :author, :appropriate_body

    def initialize(author:, appropriate_body:)
      @author = author
      @appropriate_body = appropriate_body
    end

    def self.with_author_but_no_appropriate_body(author:)
      fail(MissingAuthorError) if author.nil?

      new(author:, appropriate_body: nil)
    end

    def self.with_author_and_appropriate_body(author:, appropriate_body:)
      fail(MissingAuthorError) if author.nil?
      fail(MissingAppropriateBodyError) if appropriate_body.nil?

      new(author:, appropriate_body:)
    end

    def to_hash
      { author:, appropriate_body: }
    end
  end
end
