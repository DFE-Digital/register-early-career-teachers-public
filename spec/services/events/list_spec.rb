describe "Events::List" do
  describe "default scope" do
    it "orders by latest first by default" do
      expect(Events::List.new.scope.to_sql).to include(%(ORDER BY "events"."happened_at" DESC))
    end
  end

  describe ".for_teacher" do
    it "only selects events with a teacher_id matching the provided teacher" do
      teacher = FactoryBot.build(:teacher, id: 234)

      expect(Events::List.new.for_teacher(teacher).to_sql).to include(%(WHERE "events"."teacher_id" = #{teacher.id}))
    end
  end

  describe ".for_school" do
    it "only selects events with a teacher_id matching the provided teacher" do
      school = FactoryBot.build(:school, id: 123)

      expect(Events::List.new.for_school(school).to_sql).to include(%(WHERE "events"."school_id" = #{school.id}))
    end
  end
end
