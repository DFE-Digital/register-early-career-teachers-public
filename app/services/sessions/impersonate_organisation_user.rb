module Sessions
  module ImpersonateOrganisationUser
    class SchoolDoesNotExist < StandardError; end
    class AppropriateBodyDoesNotExist < StandardError; end

    def build_impersonate_school_user_session(urn)
      fail SchoolDoesNotExist unless School.exists?(urn:)

      new_class_name = Sessions::Users::DfEUserImpersonatingSchoolUser.name
      current_class_name = self.class.name

      to_h.merge({
        "type" => new_class_name,
        "original_type" => current_class_name,
        "school_urn" => urn
      })
    end

    def build_impersonate_appropriate_body_user_session(appropriate_body_period_id)
      fail AppropriateBodyDoesNotExist unless
        AppropriateBodyPeriod.exists?(id: appropriate_body_period_id)

      new_class_name = Sessions::Users::DfEUserImpersonatingAppropriateBodyUser.name
      current_class_name = self.class.name

      to_h.merge({
        "type" => new_class_name,
        "original_type" => current_class_name,
        "appropriate_body_period_id" => appropriate_body_period_id
      })
    end
  end
end
