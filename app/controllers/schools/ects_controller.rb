module Schools
  class ECTsController < SchoolsController
    def show
      @ect = ::ECTAtSchoolPeriod.find(params[:id])
    end
  end
end
