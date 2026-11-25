module Admin
  class APIClientsController < AdminController
    layout "full"

    before_action :set_client, only: %i[show edit update]

    def index
      @clients = API::OAuth::Client.order(:name)
    end

    def show
    end

    def new
      @client = API::OAuth::Client.new
    end

    def create
      @client = API::OAuth::Clients.new(author: current_user).create!(params: client_params)
      no_store
    rescue ActiveRecord::RecordInvalid => e
      @client = e.record
      render :new, status: :unprocessable_content
    end

    def edit
    end

    def update
      API::OAuth::Clients.new(author: current_user).update!(client: @client, params: client_params)
      redirect_to admin_api_client_path(@client), alert: "Client details updated"
    rescue ActiveRecord::RecordInvalid
      render :edit, status: :unprocessable_content
    end

  private

    def authorised? = super && current_user.product_team?

    def set_client
      @client = API::OAuth::Client.find(params.expect(:id))
    end

    def client_params
      params.expect(api_oauth_client: [:name, { redirect_uris: [] }])
    end
  end
end
