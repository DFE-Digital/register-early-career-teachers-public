module AppropriateBodies
  class TasksController < AppropriateBodiesController
    layout "full", only: :index
  end
end
