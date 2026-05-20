module Schools
  class RegistrationWindowClosedController < SchoolsController
    def show
      @reopens_on = RegistrationWindow.reopens_on.strftime("%-d %B")
    end
  end
end
