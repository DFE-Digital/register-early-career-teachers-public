describe 'Events::List' do
  describe 'default scope' do
    it 'orders by latest first by default' do
      expect(Events::List.new.scope.to_sql).to include(%(ORDER BY "events"."happened_at" DESC))
    end
  end

  describe '.for_teacher' do
    it 'selects only events with a teacher_id matching the provided teacher' do
      teacher = FactoryBot.create(:teacher)

      expect(Events::List.new.for_teacher(teacher).to_sql).to include(%(WHERE "events"."teacher_id" = #{teacher.id}))
    end
  end
end
