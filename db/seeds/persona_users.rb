def describe_user(user)
  print_seed_info("Added DfE staff user #{user.name} #{user.email}", indent: 2)
end

YAML.load_file(Rails.root.join('config/personas.yml'))
    .select { |p| p['type'] == 'DfE staff' }
    .map { |p| { name: p['name'], email: p['email'] } }
    .each do |user_params|
  User.create!(**user_params)
      .tap { |user| user.dfe_roles.create! }
      .then { |user| describe_user(user) }
end
