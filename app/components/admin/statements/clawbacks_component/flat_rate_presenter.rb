module Admin
  module Statements
    class ClawbacksComponent < ApplicationComponent
      class FlatRatePresenter < BasePresenter
        def caption_text = "Mentor clawbacks"
      end
    end
  end
end
