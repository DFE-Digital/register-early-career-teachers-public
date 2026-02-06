module AppropriateBodies
  module Unclaimed
    class ClaimedByAnotherController < AppropriateBodiesController
      layout "full", only: :index

      def index
      end
    end
  end
end
