module Admin
  class DfEUsers
    class CannotRemoveSelfError < StandardError; end
    class UserReferencedByDeclarationError < StandardError; end

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

      raise CannotRemoveSelfError if user.id == author.id

      if Declaration.exists?(voided_by_user_id: user.id)
        raise UserReferencedByDeclarationError
      end

      User.transaction do
        user.destroy!

        Events::Record.record_dfe_user_deleted_event!(
          author:,
          user_name: user.name,
          user_email: user.email,
          user_role: user.role
        )
      end
    end
  end
end
