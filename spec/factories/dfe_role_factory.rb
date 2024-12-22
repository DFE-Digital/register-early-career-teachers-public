FactoryBot.define do
  factory(:dfe_role) do
    user { nil }

    trait :admin do
      role_type { 'admin' }
    end

    trait :super_admin do
      role_type { 'super_admin' }
    end

    trait :finance do
      role_type { 'finance' }
    end
  end
end
