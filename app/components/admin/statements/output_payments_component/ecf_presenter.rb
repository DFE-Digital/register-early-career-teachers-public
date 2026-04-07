module Admin
  module Statements
    class OutputPaymentsComponent < ApplicationComponent
      class ECFPresenter < BandedPresenter
        def caption_text = "Output payments"
        def total_label = "Output payment total"
        def fee_label = "Fee per participant"
      end
    end
  end
end
