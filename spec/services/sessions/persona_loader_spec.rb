describe Sessions::PersonaLoader do
  subject { Sessions::PersonaLoader.new }

  it "loads the list of personas in config/personas.yml by default" do
    expect(subject.filename).to eql("config/personas.yml")
  end

  describe "#personas" do
    it "contains a list of personas" do
      expect(subject.personas).to all(be_a(Sessions::PersonaLoader::PersonaData))
    end

    it "loads each YAML entry into a persona" do
      yaml = YAML.load_file(Rails.root.join("config/personas.yml"))
      expect(subject.personas.size).to eql(yaml.size)
    end

    describe "Appropriate body users" do
      it "sets the right appropriate_body_period_id given a name" do
        ab = FactoryBot.create(:appropriate_body_period, name: "Umber Teaching School Hub")

        fred_jones = subject.personas.find { it.name == "Fred Jones" }

        aggregate_failures do
          expect(fred_jones.appropriate_body_period_id).to eql(ab.id)
          expect(fred_jones.school_urn).to be_nil
          expect(fred_jones.user_id).to be_nil
        end
      end
    end

    describe "School users" do
      it "sets the right school_urn given a name" do
        school = FactoryBot.create(:gias_school, :with_school, name: "Brookfield School").school

        serena_moon = subject.personas.find { it.name == "Serena Moon" }

        aggregate_failures do
          expect(serena_moon.school_urn).to eql(school.urn)
          expect(serena_moon.appropriate_body_period_id).to be_nil
          expect(serena_moon.user_id).to be_nil
        end
      end
    end

    describe "DfE staff" do
      it "sets the right user_id given a name" do
        user = FactoryBot.create(:user, name: "Norville Rogers")

        norville_rogers = subject.personas.find { it.name == "Norville Rogers" }

        aggregate_failures do
          expect(norville_rogers.user_id).to eql(user.id)
          expect(norville_rogers.school_urn).to be_nil
          expect(norville_rogers.appropriate_body_period_id).to be_nil
        end
      end
    end
  end
end
