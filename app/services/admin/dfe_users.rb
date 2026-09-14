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

    def remove_user(id)
      @user = User.find(id)

      User.transaction do
        Events::Record.record_dfe_user_deleted_event!(
          author:,
          user_name: user.name,
          user_email: user.email,
          user_role: user.role
        )

        user.destroy!
      end
    end
  end
end
