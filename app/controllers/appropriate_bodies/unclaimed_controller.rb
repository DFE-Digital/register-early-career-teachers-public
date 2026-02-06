module AppropriateBodies
  class UnclaimedController < AppropriateBodiesController
    layout "full", only: :index

    def show
    end
  end
end
