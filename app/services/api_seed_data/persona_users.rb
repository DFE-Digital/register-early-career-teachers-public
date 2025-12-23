module APISeedData
  class PersonaUsers < Base
    def plant
      return unless plantable?

      log_plant_info("persona users")

      YAML.load_file(Rails.root.join("config/personas.yml"))
          .select { |p| p["type"] == "DfE staff" }
          .map { |p| { name: p["name"], email: p["email"], role: p["role"].to_sym } }
          .each do |user_params|
        FactoryBot.create(:user, **user_params)
           .then { |user| describe_persona_user(user) }
      end
    end

  protected

    def plantable?
      super && User.none?
    end

  private

    def describe_persona_user(user)
      log_seed_info("Added DfE staff user #{user.name} #{user.email}", indent: 2)
    end
  end
end
