module AppropriateBodies
  module Unclaimed
    class NoQtsController < AppropriateBodiesController
      layout "full", only: :index

      def index
      end
    end
  end
end
