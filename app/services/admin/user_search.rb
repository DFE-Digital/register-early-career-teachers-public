module Admin
  class UserSearch
    def find_by_email_case_insensitively!(email)
      lowercase_column = Arel::Nodes::Node.new.lower(arel_table[:email])

      User.find_by!(lowercase_column.eq(email.downcase))
    end

  private

    def arel_table
      User.arel_table
    end
  end
end
