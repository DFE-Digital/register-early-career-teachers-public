RSpec.describe Admin::ClaimAnECT::RegisterECT do
  let(:user) { FactoryBot.create(:user) }
  let(:appropriate_body) { FactoryBot.create(:appropriate_body) }
  let(:pending_induction_submission) { FactoryBot.create(:pending_induction_submission) }
  let(:service) { described_class.new(pending_induction_submission:, author: user) }

  describe '#register' do
    let(:valid_params) do
      {
        started_on: "2023-09-01",
        induction_programme: "fip",
        trs_induction_status: "InProgress",
        appropriate_body_id: appropriate_body.id,
        number_of_terms: "2"
      }
    end

    context 'when the parameters are valid' do
      it 'creates a new teacher' do
        expect { service.register(valid_params) }.to change(Teacher, :count).by(1)
      end

      it 'creates a new induction period' do
        expect { service.register(valid_params) }.to change(InductionPeriod, :count).by(1)
      end

      it 'assigns the correct attributes to the teacher' do
        service.register(valid_params)
        teacher = Teacher.last

        expect(teacher.trn).to eq(pending_induction_submission.trn)
        expect(teacher.trs_first_name).to eq(pending_induction_submission.trs_first_name)
        expect(teacher.trs_last_name).to eq(pending_induction_submission.trs_last_name)
        expect(teacher.trs_date_of_birth).to eq(pending_induction_submission.trs_date_of_birth)
        expect(teacher.trs_email_address).to eq(pending_induction_submission.trs_email_address)
      end

      it 'assigns the correct attributes to the induction period' do
        service.register(valid_params)
        induction_period = InductionPeriod.last

        expect(induction_period.teacher).to eq(Teacher.last)
        expect(induction_period.appropriate_body).to eq(appropriate_body)
        expect(induction_period.started_on).to eq(Date.parse("2023-09-01"))
        expect(induction_period.induction_programme).to eq("fip")
        expect(induction_period.number_of_terms).to eq(2)
      end

      it 'updates the pending induction submission' do
        service.register(valid_params)
        pending_induction_submission.reload

        expect(pending_induction_submission.appropriate_body_id).to eq(appropriate_body.id)
        expect(pending_induction_submission.started_on).to eq(Date.parse("2023-09-01"))
        expect(pending_induction_submission.induction_programme).to eq("fip")
        expect(pending_induction_submission.number_of_terms).to eq(2)
      end

      it 'returns true' do
        expect(service.register(valid_params)).to be true
      end
    end

    context 'when the parameters are invalid' do
      let(:invalid_params) do
        {
          started_on: "",
          induction_programme: "",
          trs_induction_status: "",
          appropriate_body_id: "",
          number_of_terms: ""
        }
      end

      it 'does not create a new teacher' do
        expect { service.register(invalid_params) }.not_to change(Teacher, :count)
      end

      it 'does not create a new induction period' do
        expect { service.register(invalid_params) }.not_to change(InductionPeriod, :count)
      end

      it 'returns false' do
        expect(service.register(invalid_params)).to be false
      end

      it 'adds errors to the pending induction submission' do
        service.register(invalid_params)
        expect(pending_induction_submission.errors).to be_present
      end
    end

    context 'when the appropriate body is not provided' do
      let(:params_without_ab) do
        {
          started_on: "2023-09-01",
          induction_programme: "fip",
          trs_induction_status: "InProgress",
          appropriate_body_id: "",
          number_of_terms: "2"
        }
      end

      it 'does not create a new teacher' do
        expect { service.register(params_without_ab) }.not_to change(Teacher, :count)
      end

      it 'returns false' do
        expect(service.register(params_without_ab)).to be false
      end
    end
  end
end
