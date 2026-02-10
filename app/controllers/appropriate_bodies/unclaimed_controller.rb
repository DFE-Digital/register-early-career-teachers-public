module AppropriateBodies
  class UnclaimedController < AppropriateBodiesController
    layout "full", only: :index

    def index
    end
  end
end
