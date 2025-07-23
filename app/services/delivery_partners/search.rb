module DeliveryPartners
  class Search
    def initialize(query_string = nil)
      @scope = DeliveryPartner

      @query_string = query_string
    end

    def search
      query = if @query_string.blank?
                @scope.all
              else
                @scope.where("name ILIKE ?", "%#{@query_string}%")
              end

      query.order(name: 'asc')
    end
  end
end
