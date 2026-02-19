module Shared
  class CountCardComponent < ApplicationComponent
    attr_reader :count, :description, :colour, :classes

    def initialize(count:, description:, colour: nil, classes: nil)
      @count = count
      @description = description
      @colour = colour
      @classes = classes
    end

    def card_classes
      "app-card--#{colour} card"
    end
  end
end
