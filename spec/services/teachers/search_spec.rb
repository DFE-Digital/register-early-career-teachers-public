describe Teachers::Search do
  describe '#initialize' do
    context 'with default parameters' do
      subject { described_class.new }

      it 'sets the scope to all teachers' do
        expect(subject.scope).to eq(Teacher.all)
      end
    end

    context 'with nil query_string' do
      it 'ignores nil query strings' do
        expect { described_class.new(query_string: nil) }.not_to raise_error
      end
    end
  end

  describe '#search' do
    let(:ab1) { FactoryBot.create(:appropriate_body) }
    let(:ab2) { FactoryBot.create(:appropriate_body) }
    let(:ab3) { FactoryBot.create(:appropriate_body) }

    let(:teacher1) { FactoryBot.create(:teacher) }
    let(:teacher2) { FactoryBot.create(:teacher) }
    let(:teacher3) { FactoryBot.create(:teacher) }

    let!(:induction_period1) { FactoryBot.create(:induction_period, :active, teacher: teacher1, appropriate_body: ab1) }
    let!(:induction_period2) { FactoryBot.create(:induction_period, :active, teacher: teacher2, appropriate_body: ab2) }

    describe 'belonging to appropriate bodies' do
      context 'when one appropriate body is provided' do
        subject { Teachers::Search.new(appropriate_bodies: ab1) }

        it 'includes teachers with ongoing induction periods with the specified appropriate bodies' do
          expect(subject.search).to include(teacher1)
        end

        it 'excludes teachers without ongoing induction periods with the specified appropriate bodies' do
          expect(subject.search).not_to include(teacher2)
        end
      end

      context 'when multiple appropriate bodies are provided' do
        subject { Teachers::Search.new(appropriate_bodies: [ab1, ab3]) }

        let!(:induction_period3) { FactoryBot.create(:induction_period, :active, teacher: teacher3, appropriate_body: ab3) }

        it 'includes teachers with ongoing induction periods with the specified appropriate bodies' do
          expect(subject.search).to include(teacher1, teacher3)
        end

        it 'excludes teachers without ongoing induction periods with the specified appropriate bodies' do
          expect(subject.search).not_to include(teacher2)
        end
      end

      context 'when no appropriate bodies are provided' do
        subject { Teachers::Search.new(appropriate_bodies: []) }

        it 'no teachers are returned' do
          expect(subject.search).to be_empty
        end
      end

      context 'when no appropriate bodies argument is provided' do
        subject { Teachers::Search.new }

        it 'all teachers are returned' do
          expect(subject.search).to include(teacher1, teacher2)
        end
      end
    end

    describe 'status-based filtering with appropriate bodies' do
      let(:teacher_with_open_induction) { FactoryBot.create(:teacher) }
      let(:teacher_with_completed_induction) { FactoryBot.create(:teacher) }
      let(:teacher_with_no_induction) { FactoryBot.create(:teacher) }

      let!(:open_induction_period) { FactoryBot.create(:induction_period, :active, teacher: teacher_with_open_induction, appropriate_body: ab1) }
      let!(:completed_induction_period) { FactoryBot.create(:induction_period, :pass, teacher: teacher_with_completed_induction, appropriate_body: ab1) }

      context 'when status is "open"' do
        subject { Teachers::Search.new(appropriate_bodies: ab1, status: 'open') }

        it 'returns only teachers with current/ongoing induction periods' do
          expect(subject.search).to include(teacher_with_open_induction)
          expect(subject.search).not_to include(teacher_with_completed_induction)
          expect(subject.search).not_to include(teacher_with_no_induction)
        end

        it 'delegates to ects_service.with_status' do
          ects_service = instance_double(AppropriateBodies::ECTs)
          allow(AppropriateBodies::ECTs).to receive(:new).with(ab1).and_return(ects_service)
          allow(ects_service).to receive(:with_status).with('open').and_return(Teacher.none)

          subject.search

          expect(ects_service).to have_received(:with_status).with('open')
        end
      end

      context 'when status is "closed"' do
        subject { Teachers::Search.new(appropriate_bodies: ab1, status: 'closed') }

        it 'returns only teachers with completed induction periods' do
          expect(subject.search).to include(teacher_with_completed_induction)
          expect(subject.search).not_to include(teacher_with_open_induction)
          expect(subject.search).not_to include(teacher_with_no_induction)
        end

        it 'delegates to ects_service.with_status' do
          ects_service = instance_double(AppropriateBodies::ECTs)
          allow(AppropriateBodies::ECTs).to receive(:new).with(ab1).and_return(ects_service)
          allow(ects_service).to receive(:with_status).with('closed').and_return(Teacher.none)

          subject.search

          expect(ects_service).to have_received(:with_status).with('closed')
        end
      end

      context 'when status is nil or any other value' do
        subject { Teachers::Search.new(appropriate_bodies: ab1, status: nil) }

        it 'returns teachers with both current and completed induction periods' do
          expect(subject.search).to include(teacher_with_open_induction, teacher_with_completed_induction)
          expect(subject.search).not_to include(teacher_with_no_induction)
        end

        it 'delegates to ects_service.with_status' do
          ects_service = instance_double(AppropriateBodies::ECTs)
          allow(AppropriateBodies::ECTs).to receive(:new).with(ab1).and_return(ects_service)
          allow(ects_service).to receive(:with_status).with(nil).and_return(Teacher.none)

          subject.search

          expect(ects_service).to have_received(:with_status).with(nil)
        end
      end

      context 'when status is an unknown value' do
        subject { Teachers::Search.new(appropriate_bodies: ab1, status: 'unknown_status') }

        it 'defaults to returning teachers with both current and completed induction periods' do
          expect(subject.search).to include(teacher_with_open_induction, teacher_with_completed_induction)
          expect(subject.search).not_to include(teacher_with_no_induction)
        end

        it 'delegates to ects_service.with_status for unknown statuses' do
          ects_service = instance_double(AppropriateBodies::ECTs)
          allow(AppropriateBodies::ECTs).to receive(:new).with(ab1).and_return(ects_service)
          allow(ects_service).to receive(:with_status).with('unknown_status').and_return(Teacher.none)

          subject.search

          expect(ects_service).to have_received(:with_status).with('unknown_status')
        end
      end

      context 'when appropriate_bodies is :ignore' do
        subject { Teachers::Search.new(appropriate_bodies: :ignore, status: 'open') }

        it 'does not filter by appropriate bodies regardless of status' do
          all_teachers = [teacher1, teacher2, teacher3, teacher_with_open_induction, teacher_with_completed_induction, teacher_with_no_induction]
          expect(subject.search).to include(*all_teachers)
        end

        it 'does not call AppropriateBodies::ECTs when appropriate_bodies is ignored' do
          expect(AppropriateBodies::ECTs).not_to receive(:new)

          subject.search
        end
      end
    end

    describe 'when a query string is provided' do
      context 'when there are 7 digit numbers in the search string' do
        let(:teacher1) { FactoryBot.create(:teacher, trn: '1234567') }
        let(:teacher2) { FactoryBot.create(:teacher, trn: '2345678') }

        it 'searches for all present 7 digit numbers (TRNs)' do
          result = described_class.new(query_string: 'the quick brown 1234567 jumped over the lazy 2345678').search

          expect(result).to include(teacher1, teacher2)
        end
      end

      context 'when the search string contains some text' do
        let(:teacher1) { FactoryBot.create(:teacher, trs_first_name: 'Captain', trs_last_name: 'Scrummy') }

        it 'initiates a full text search with the given search string' do
          result = described_class.new(query_string: 'Captain Scrummy').search

          expect(result).to include(teacher1)
        end
      end
    end

    describe 'when both an appropriate body and query string are provided' do
      let(:teacher1) { FactoryBot.create(:teacher, trs_first_name: 'Joey') }
      let(:teacher2) { FactoryBot.create(:teacher, trs_first_name: 'Joey') }

      it 'scopes the query to the selected appropriate body' do
        result = described_class.new(query_string: 'Joey', appropriate_bodies: ab1).search

        expect(result).to include(teacher1)
        expect(result).not_to include(teacher2)
      end
    end

    context 'with ignored parameters' do
      it 'returns all teachers when all parameters are ignored' do
        result = described_class.new.search

        expect(result).to include(teacher1, teacher2)
      end
    end

    describe "searching for ECTs at a school" do
      context 'when one school is present' do
        it 'only selects ECTs who are currently at the given school' do
          query = Teachers::Search.new(ect_at_school: 123).search

          expect(query.to_sql).to include(%("ect_at_school_periods"."school_id" = 123))
        end

        describe 'current and future teachers' do
          let(:teacher) { FactoryBot.create(:teacher, trs_first_name: 'John', trs_last_name: 'Connor') }
          let(:school) { FactoryBot.create(:school) }

          context 'when ECT has left the school' do
            let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :past, school:, teacher:) }

            it 'returns no teachers' do
              expect(Teachers::Search.new(ect_at_school: school).search).to be_empty
            end
          end

          context 'when currently an ECT at the school' do
            let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :active, school:, teacher:) }

            it 'returns the teacher' do
              expect(Teachers::Search.new(ect_at_school: school).search).to include(teacher)
            end
          end

          context 'when ECT is scheduled to join the school' do
            let!(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :future, school:, teacher:) }

            it 'returns the teacher' do
              expect(Teachers::Search.new(ect_at_school: school).search).to include(teacher)
            end
          end
        end
      end

      context 'when multiple schools are present' do
        it 'only selects ECTs who are currently at the given school' do
          query = Teachers::Search.new(ect_at_school: [123, 456]).search

          expect(query.to_sql).to include(%{"ect_at_school_periods"."school_id" IN (123, 456)})
        end
      end

      context 'when absent' do
        it 'does not join ect_at_school_periods' do
          query = Teachers::Search.new.search

          expect(query.to_sql).not_to include('ect_at_school_periods')
        end
      end

      describe 'ordering the results' do
        let(:started_on) { 2.years.ago }

        let(:school1) { FactoryBot.create(:school) }
        let(:mentored_teacher1) { FactoryBot.create(:teacher) }
        let(:mentored_teacher2) { FactoryBot.create(:teacher) }

        # unmentored
        let!(:ect_at_school_period1) { FactoryBot.create(:ect_at_school_period, :active, teacher: teacher1, school: school1, started_on:, created_at: 2.days.ago) }
        let!(:ect_at_school_period2) { FactoryBot.create(:ect_at_school_period, :active, teacher: teacher2, school: school1, started_on:, created_at: 1.day.ago) }

        # mentored
        let!(:mentor_at_school_period1) { FactoryBot.create(:mentor_at_school_period, :active, teacher: teacher3, school: school1, started_on:) }
        let!(:ect_at_school_period3) { FactoryBot.create(:ect_at_school_period, :active, teacher: mentored_teacher1, school: school1, started_on:, created_at: 2.days.ago) }
        let!(:ect_at_school_period4) { FactoryBot.create(:ect_at_school_period, :active, teacher: mentored_teacher2, school: school1, started_on:, created_at: 1.day.ago) }

        let!(:mentorship_period1) { FactoryBot.create(:mentorship_period, mentee: ect_at_school_period3, mentor: mentor_at_school_period1, started_on:) }
        let!(:mentorship_period2) { FactoryBot.create(:mentorship_period, mentee: ect_at_school_period4, mentor: mentor_at_school_period1, started_on:) }

        it 'orders with unmentored teachers first, then by registration date' do
          results = Teachers::Search.new(ect_at_school: school1).search

          expect(results).to eq([teacher2, teacher1, mentored_teacher2, mentored_teacher1])
        end
      end
    end

    it 'orders results by last name, first name, and id' do
      query = described_class.new.search.to_sql
      order_clause = %(ORDER BY "teachers"."trs_last_name" ASC, "teachers"."trs_first_name" ASC, "teachers"."id" ASC)

      expect(query).to include(order_clause)
    end
  end
end
