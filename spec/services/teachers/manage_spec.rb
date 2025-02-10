RSpec.describe Teachers::Manage do
  subject(:service) { described_class.new(pending_induction_submission) }
  let(:teacher) { FactoryBot.create(:teacher, trs_first_name: "Barry", trs_last_name: "Allen") }
  let(:pending_induction_submission) do
    FactoryBot.create(:pending_induction_submission,
                      trn: teacher.trn,
                      trs_first_name: "John",
                      trs_last_name: "Doe")
  end

  xdescribe '#create_or_update!' do
  end

  xdescribe '#set_trs_name' do
  end

  xdescribe '#set_trs_qts_awarded_on' do
  end

  describe 'changes' do
    before { service.create_or_update! }

    # describe '#qts_awarded_on_changed?' do
    #   it { expect(service).to be_qts_awarded_on_changed }
    # end

    # describe '#changed_qts_awarded_on' do
    #   it { expect(service.changed_qts_awarded_on).to eq({ old_award_date: "", new_award_date: "" }) }
    # end

    describe '#name_changed?' do
      it { expect(service).to be_name_changed }
    end

    describe '#changed_names' do
      it { expect(service.changed_names).to eq({ old_name: "Barry Allen", new_name: "John Doe" }) }
    end
  end
end
