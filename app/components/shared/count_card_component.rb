module Shared
  class CountCardComponent < ApplicationComponent
    attr_reader :count, :description, :colour

    def initialize(count:, description:, colour:)
      @count = count
      @description = description
      @colour = colour
    end

    def card_classes
      "app-card--#{colour} card"
    end
  end
end
