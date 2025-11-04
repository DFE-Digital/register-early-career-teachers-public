module SandboxSeedData
  class Teachers < Base
    NUMBER_OF_RECORDS = 100

    def plant
      return unless plantable?

      log_plant_info("teachers")

      NUMBER_OF_RECORDS.times { create_teacher }
    end

  private

    def create_teacher
      teacher = FactoryBot.build(:teacher, :with_realistic_name).tap do
        random_date = rand(1..100).days.ago
        it.update!(
          created_at: random_date,
          updated_at: random_date,
          api_updated_at: random_date
        )
      end

      log_seed_info(::Teachers::Name.new(teacher).full_name, indent: 2)
    end
  end
end
