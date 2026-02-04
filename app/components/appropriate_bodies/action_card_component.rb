module AppropriateBodies
  class ActionCardComponent < ApplicationComponent
    attr_reader :url, :heading, :body

    def initialize(url:, heading:, body:)
      @url = url
      @heading = heading
      @body = body
    end
  end
end
