module Admin
  module Statements
    class DeclarationComponent < ApplicationComponent
      class ECFPresenter < BandedPresenter
        def header = "Total"
      end
    end
  end
end
