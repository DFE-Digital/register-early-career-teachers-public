class DfESignInRole < ApplicationRecord
  enum :code,
       %w[school_user appropriate_body_user].index_by(&:itself),
       validate: { message: "Must be school_user or appropriate_body_user" }

  validates :dfe_sign_in_role_id, presence: true, uniqueness: true
  validates :code, uniqueness: true
end
