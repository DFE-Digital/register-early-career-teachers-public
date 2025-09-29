FactoryBot.define do
  factory(:dfe_user, class: 'Sessions::Users::DfEUser') do
    skip_create

    initialize_with do
      User.create!(email:, name:, role:)

      new(email:)
    end

    sequence(:email) { |n| "admin.user.#{n}@example.com" }
    sequence(:name) { |n| "Admin User #{n}" }

    role { User::ROLES.keys.sample.to_s }
  end
end
