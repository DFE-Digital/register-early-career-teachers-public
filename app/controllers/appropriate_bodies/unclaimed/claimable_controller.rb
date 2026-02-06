module AppropriateBodies
  module Unclaimed
    class ClaimableController < AppropriateBodiesController
      layout "full", only: :index

      def index
      end
    end
  end
end
