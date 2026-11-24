module API::OAuth
  class Clients
    attr_reader :author

    def initialize(author:)
      @author = author
    end

    def create!(params:)
      Client.new(**params).tap do |client|
        modifications = client.changes.slice(:name, :redirect_uris)

        Client.transaction do
          client.save!
          Events::Record.record_api_client_created_event!(author:, client:, modifications:)
        end
      end
    end

    def update!(client:, params:)
      client.assign_attributes(params)
      modifications = client.changes.slice(:name, :redirect_uris)

      Client.transaction do
        client.save!
        Events::Record.record_api_client_updated_event!(author:, client:, modifications:) if modifications.any?
      end
    end

    def rotate_secret!(client:)
      client.rotate_client_secret

      Client.transaction do
        client.save!
        Events::Record.record_api_client_secret_rotated_event!(author:, client:)
      end
    end
  end
end
