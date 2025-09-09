module Sessions
  module ImpersonateSchoolUser
    class SchoolDoesNotExist < StandardError; end

    def build_impersonate_school_user_session(urn)
      fail SchoolDoesNotExist unless school_exists?(urn)

      new_class_name = Sessions::Users::DfEUserImpersonatingSchoolUser.name
      current_class_name = self.class.name

      to_h.merge({
        'type' => new_class_name,
        'original_type' => current_class_name,
        'school_urn' => urn
      })
    end

  private

    def school_exists?(urn)
      School.exists?(urn:)
    end
  end
end
