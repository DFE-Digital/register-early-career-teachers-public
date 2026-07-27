module Admin
  module Statements
    class ClawbacksComponent < ApplicationComponent
      class BandedPresenter < BasePresenter
        def caption_text = "ECT clawbacks"

      private

        def payment_type(output)
          super + " (Band #{output.band_term.letter})"
        end
      end
    end
  end
end
