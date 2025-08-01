module DeliveryPartners
  class Search
    def initialize(query_string = nil)
      @query_string = query_string
    end

    def search
      scope = DeliveryPartner.all

      if @query_string.present?
        scope = scope.where("name ILIKE ?", "%#{@query_string}%")
      end

      scope.order(name: :asc)
    end
  end
end
