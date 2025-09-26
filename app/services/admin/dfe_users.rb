module Admin
  class DfEUsers
    attr_reader :author, :user

    def initialize(author:)
      @author = author
    end

    def create_user(params)
      @user = User.new(params)

      User.transaction do
        modifications = user.changes

        raise ActiveRecord::Rollback unless user.save

        Events::Record.record_dfe_user_created_event!(author:, user:, modifications:)
      end
    end

    def update_user(id, params)
      @user = User.find(id)
      user.assign_attributes(params)

      User.transaction do
        modifications = user.changes

        raise ActiveRecord::Rollback unless user.save

        Events::Record.record_dfe_user_updated_event!(author:, user:, modifications:)
      end
    end
  end
end
