describe Teachers::Search do
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
        let!(:induction_period3) { FactoryBot.create(:induction_period, :active, teacher: teacher3, appropriate_body: ab3) }
        subject { Teachers::Search.new(appropriate_bodies: [ab1, ab3]) }

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

    it 'orders results by last name, first name, and id' do
      query = described_class.new.search.to_sql
      order_clause = %(ORDER BY "teachers"."trs_last_name" ASC, "teachers"."trs_first_name" ASC, "teachers"."id" ASC)

      expect(query).to include(order_clause)
    end
  end
end
