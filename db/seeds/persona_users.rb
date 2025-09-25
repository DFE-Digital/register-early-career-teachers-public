def describe_user(user)
  print_seed_info("Added DfE staff user #{user.name} #{user.email}", indent: 2)
end

YAML.load_file(Rails.root.join('config/personas.yml'))
    .select { |p| p['type'] == 'DfE staff' }
    .map { |p| { name: p['name'], email: p['email'], role: p['role'].to_sym } }
    .each do |user_params|
  FactoryBot.create(:user, **user_params)
     .then { |user| describe_user(user) }
end
