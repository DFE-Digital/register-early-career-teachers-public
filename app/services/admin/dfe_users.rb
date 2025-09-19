module Admin
  class DfEUsers
    class AlreadyExists < StandardError; end

    attr_reader :author, :user

    def initialize(author:)
      @author = author
    end

    def create_user(params)
      @user = User.new(params)
      fail AlreadyExists if user.persisted?

      User.transaction do
        modifications = user.changes
        user.save

        Events::Record.record_dfe_user_created_event!(author:, user:, modifications:)
      end
    end

    def update_user(id, params)
      @user = User.find(id)
      user.assign_attributes(params)

      User.transaction do
        modifications = user.changes
        user.save

        Events::Record.record_dfe_user_updated_event!(author:, user:, modifications:)
      end
    end
  end
end
