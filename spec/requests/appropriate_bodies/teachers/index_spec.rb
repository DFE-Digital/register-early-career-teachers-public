RSpec.describe "Appropriate Body teacher index page", type: :request do
  include AuthHelper
  let(:appropriate_body) { create(:appropriate_body) }

  describe 'GET /appropriate-body/teachers' do
    context 'when not signed in' do
      it 'redirects to the root page' do
        get("/appropriate-body/teachers")

        expect(response).to be_redirection
        expect(response.redirect_url).to eql(root_url)
      end
    end

    context 'when signed in as an appropriate body user' do
      let!(:user) { sign_in_as(:appropriate_body_user, appropriate_body:) }

      context "when there are more than 50 teachers" do
        let!(:additional_teachers) do
          create_list(:teacher, 51, trs_first_name: "John", trs_last_name: "Smith").tap do |teachers|
            teachers.each do |teacher|
              create(:induction_period, :active, teacher:, appropriate_body:)
            end
          end
        end

        before do
          get("/appropriate-body/teachers")
        end

        it 'displays pagination' do
          expect(response.body).to include('govuk-pagination')
        end
      end

      context "with open and closed induction filtering" do
        let!(:alice_johnson) do
          create(:teacher, trs_first_name: 'Alice', trs_last_name: 'Johnson', trn: '1000001', trs_induction_status: 'InProgress').tap do |teacher|
            create(:induction_period, :active, teacher:, appropriate_body:, started_on: 3.months.ago)
          end
        end

        let!(:bob_williams) do
          create(:teacher, trs_first_name: 'Bob', trs_last_name: 'Williams', trn: '1000002', trs_induction_status: 'RequiredToComplete').tap do |teacher|
            create(:induction_period, :active, teacher:, appropriate_body:, started_on: 2.months.ago)
          end
        end

        let!(:charlie_brown) do
          create(:teacher, trs_first_name: 'Charlie', trs_last_name: 'Brown', trn: '1000003', trs_induction_status: 'InProgress').tap do |teacher|
            create(:induction_period, :active, teacher:, appropriate_body:, started_on: 1.month.ago)
          end
        end

        let!(:david_davis) do
          create(:teacher, trs_first_name: 'David', trs_last_name: 'Davis', trn: '2000001', trs_induction_status: 'Passed').tap do |teacher|
            create(:induction_period, :pass, teacher:, appropriate_body:, started_on: 1.year.ago, finished_on: 2.months.ago, number_of_terms: 6)
          end
        end

        let!(:emma_wilson) do
          create(:teacher, trs_first_name: 'Emma', trs_last_name: 'Wilson', trn: '2000002', trs_induction_status: 'Failed').tap do |teacher|
            create(:induction_period, :fail, teacher:, appropriate_body:, started_on: 1.year.ago, finished_on: 1.month.ago, number_of_terms: 6)
          end
        end

        let!(:frank_miller) do
          create(:teacher, trs_first_name: 'Frank', trs_last_name: 'Miller', trn: '2000003', trs_induction_status: 'Exempt').tap do |teacher|
            create(:induction_period, :pass, teacher:, appropriate_body:, started_on: 1.year.ago, finished_on: 3.months.ago, number_of_terms: 6)
          end
        end

        context 'default open inductions view' do
          before { get('/appropriate-body/teachers') }

          it 'returns successful response' do
            expect(response).to be_successful
          end

          it 'displays correct count of open inductions' do
            expect(response.body).to include('3 open inductions')
          end

          it 'displays navigation link to closed inductions with correct count' do
            expect(response.body).to include('View closed inductions (3)')
          end

          it 'displays only open teachers in the table' do
            # Should include open teachers
            expect(response.body).to include("#{alice_johnson.trs_first_name} #{alice_johnson.trs_last_name}")
            expect(response.body).to include("#{bob_williams.trs_first_name} #{bob_williams.trs_last_name}")
            expect(response.body).to include("#{charlie_brown.trs_first_name} #{charlie_brown.trs_last_name}")

            # Should NOT include closed teachers
            expect(response.body).not_to include("#{david_davis.trs_first_name} #{david_davis.trs_last_name}")
            expect(response.body).not_to include("#{emma_wilson.trs_first_name} #{emma_wilson.trs_last_name}")
            expect(response.body).not_to include("#{frank_miller.trs_first_name} #{frank_miller.trs_last_name}")
          end

          it 'displays correct TRNs for open teachers only' do
            expect(response.body).to include(alice_johnson.trn)
            expect(response.body).to include(bob_williams.trn)
            expect(response.body).to include(charlie_brown.trn)

            expect(response.body).not_to include(david_davis.trn)
            expect(response.body).not_to include(emma_wilson.trn)
            expect(response.body).not_to include(frank_miller.trn)
          end

          it 'does not display closed induction statuses' do
            # Should not show passed/failed/exempt status tags for closed teachers
            expect(response.body).not_to include("#{david_davis.trs_first_name} #{david_davis.trs_last_name}")
            expect(response.body).not_to include("#{emma_wilson.trs_first_name} #{emma_wilson.trs_last_name}")
            expect(response.body).not_to include("#{frank_miller.trs_first_name} #{frank_miller.trs_last_name}")
          end
        end

        context 'explicit open inductions view' do
          before { get('/appropriate-body/teachers?status=open') }

          it 'returns successful response' do
            expect(response).to be_successful
          end

          it 'displays correct count of open inductions' do
            expect(response.body).to include('3 open inductions')
          end

          it 'displays only open teachers in the table' do
            expect(response.body).to include("#{alice_johnson.trs_first_name} #{alice_johnson.trs_last_name}")
            expect(response.body).to include("#{bob_williams.trs_first_name} #{bob_williams.trs_last_name}")
            expect(response.body).to include("#{charlie_brown.trs_first_name} #{charlie_brown.trs_last_name}")

            expect(response.body).not_to include("#{david_davis.trs_first_name} #{david_davis.trs_last_name}")
            expect(response.body).not_to include("#{emma_wilson.trs_first_name} #{emma_wilson.trs_last_name}")
            expect(response.body).not_to include("#{frank_miller.trs_first_name} #{frank_miller.trs_last_name}")
          end
        end

        context 'closed inductions view' do
          before { get('/appropriate-body/teachers?status=closed') }

          it 'returns successful response' do
            expect(response).to be_successful
          end

          it 'displays correct count of closed inductions' do
            expect(response.body).to include('3 closed inductions')
          end

          it 'displays navigation link to open inductions with correct count' do
            expect(response.body).to include('View open inductions (3)')
          end

          it 'displays only closed teachers in the table' do
            # Should include closed teachers
            expect(response.body).to include("#{david_davis.trs_first_name} #{david_davis.trs_last_name}")
            expect(response.body).to include("#{emma_wilson.trs_first_name} #{emma_wilson.trs_last_name}")
            expect(response.body).to include("#{frank_miller.trs_first_name} #{frank_miller.trs_last_name}")

            # Should NOT include open teachers
            expect(response.body).not_to include("#{alice_johnson.trs_first_name} #{alice_johnson.trs_last_name}")
            expect(response.body).not_to include("#{bob_williams.trs_first_name} #{bob_williams.trs_last_name}")
            expect(response.body).not_to include("#{charlie_brown.trs_first_name} #{charlie_brown.trs_last_name}")
          end

          it 'displays correct TRNs for closed teachers only' do
            expect(response.body).to include(david_davis.trn)
            expect(response.body).to include(emma_wilson.trn)
            expect(response.body).to include(frank_miller.trn)

            expect(response.body).not_to include(alice_johnson.trn)
            expect(response.body).not_to include(bob_williams.trn)
            expect(response.body).not_to include(charlie_brown.trn)
          end

          it 'displays correct induction statuses for closed teachers' do
            expect(response.body).to include('Passed')
            expect(response.body).to include('Failed')
            expect(response.body).to include('Exempt')
          end
        end

        context 'table row counting' do
          it 'open page shows exactly 3 teacher rows' do
            get('/appropriate-body/teachers')

            # Count tbody tr elements (excluding header)
            doc = Nokogiri::HTML(response.body)
            teacher_rows = doc.css('tbody tr')
            expect(teacher_rows.length).to eq(3)
          end

          it 'closed page shows exactly 3 teacher rows' do
            get('/appropriate-body/teachers?status=closed')

            # Count tbody tr elements (excluding header)
            doc = Nokogiri::HTML(response.body)
            teacher_rows = doc.css('tbody tr')
            expect(teacher_rows.length).to eq(3)
          end
        end

        context 'search functionality' do
          context 'searching open inductions' do
            it 'filters open teachers correctly' do
              get('/appropriate-body/teachers?q=Alice')

              expect(response.body).to include("#{alice_johnson.trs_first_name} #{alice_johnson.trs_last_name}")
              expect(response.body).not_to include("#{bob_williams.trs_first_name} #{bob_williams.trs_last_name}")
              expect(response.body).not_to include("#{charlie_brown.trs_first_name} #{charlie_brown.trs_last_name}")
              expect(response.body).not_to include("#{david_davis.trs_first_name} #{david_davis.trs_last_name}")
            end
          end

          context 'searching closed inductions' do
            it 'filters closed teachers correctly' do
              get('/appropriate-body/teachers?status=closed&q=David')

              expect(response.body).to include("#{david_davis.trs_first_name} #{david_davis.trs_last_name}")
              expect(response.body).not_to include("#{emma_wilson.trs_first_name} #{emma_wilson.trs_last_name}")
              expect(response.body).not_to include("#{frank_miller.trs_first_name} #{frank_miller.trs_last_name}")
              expect(response.body).not_to include("#{alice_johnson.trs_first_name} #{alice_johnson.trs_last_name}")
            end
          end
        end

        context 'edge cases' do
          context 'teacher with finished induction period but no outcome' do
            let!(:edge_case_teacher) do
              teacher = create(:teacher,
                               trs_first_name: 'Grace',
                               trs_last_name: 'NoOutcome',
                               trn: '3000001',
                               trs_induction_status: 'InProgress')
              # Create finished period with no outcome - should not appear in either list
              create(:induction_period, teacher:, appropriate_body:,
                                        started_on: 1.year.ago, finished_on: 1.month.ago, outcome: nil, number_of_terms: 6)
              teacher
            end

            it 'does not appear in open inductions' do
              get('/appropriate-body/teachers')
              expect(response.body).not_to include("#{edge_case_teacher.trs_first_name} #{edge_case_teacher.trs_last_name}")
            end

            it 'does not appear in closed inductions' do
              get('/appropriate-body/teachers?status=closed')
              expect(response.body).not_to include("#{edge_case_teacher.trs_first_name} #{edge_case_teacher.trs_last_name}")
            end
          end
        end
      end
    end
  end
end
