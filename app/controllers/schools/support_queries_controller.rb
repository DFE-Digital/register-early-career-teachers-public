module Schools
  class SupportQueriesController < SchoolsController
    def new
      @support_query = SupportQuery.new
    end

    def create
      @support_query = SupportQuery.new(support_query_params)

      if @support_query.save
        @support_query.send_to_zendesk_later
        render
      else
        render :new
      end
    end

  private

    def support_query_params
      params
        .expect(support_query: [:message])
        .merge(current_user_params)
    end

    def current_user_params
      {
        name: current_user.name,
        email: current_user.email,
        school_name: current_user.school.name,
        school_urn: current_user.school.urn,
      }
    end
  end
end
