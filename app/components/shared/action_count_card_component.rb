module Shared
  class ActionCountCardComponent < ApplicationComponent
    attr_reader :url, :count, :description, :colour

    def initialize(url:, count:, description:, colour:)
      @url = url
      @count = count
      @description = description
      @colour = colour
    end
  end
end
