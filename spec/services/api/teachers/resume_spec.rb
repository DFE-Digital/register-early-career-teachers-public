RSpec.describe API::Teachers::Resume, type: :model do
  subject(:instance) do
    described_class.new(
      lead_provider_id:,
      teacher_api_id:,
      course_identifier:
    )
  end

  it_behaves_like "an API teacher shared action" do
    describe "validations" do
      %i[ect mentor].each do |trainee_type|
        context "for #{trainee_type}" do
          let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", :ongoing, started_on: 2.months.ago) }
          let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :ongoing, "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on) }
          let(:course_identifier) { trainee_type == :ect ? "ecf-induction" : "ecf-mentor" }

          context "when teacher is already active" do
            it { is_expected.to have_one_error_per_attribute }
            it { is_expected.to have_error(:teacher_api_id, "The '#/teacher_api_id' is already active.") }
          end

          context "guarded error messages" do
            subject(:instance) { described_class.new }

            it { is_expected.to have_one_error_per_attribute }
          end
        end
      end
    end

    describe "#resume" do
      %i[ect mentor].each do |trainee_type|
        context "for #{trainee_type}" do
          let(:at_school_period) { FactoryBot.create(:"#{trainee_type}_at_school_period", started_on: 6.months.ago) }
          let(:course_identifier) { trainee_type == :ect ? "ecf-induction" : "ecf-mentor" }

          context "when invalid" do
            let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", :ongoing) }
            let(:teacher_api_id) { SecureRandom.uuid }

            it { expect(instance.resume).to be(false) }
            it { expect { instance.resume }.not_to(change { training_period.reload.attributes }) }
          end

          context "when valid" do
            let!(:training_period) { FactoryBot.create(:training_period, :"for_#{trainee_type}", "#{trainee_type}_at_school_period": at_school_period, started_on: at_school_period.started_on) }

            it "resumes the training period via resume service" do
              resume_service = double("Teachers::Resume")
              author = an_instance_of(Events::LeadProviderAPIAuthor)

              allow(Teachers::Resume).to receive(:new).with(author:, lead_provider:, teacher:, training_period:).and_return(resume_service)
              allow(resume_service).to receive(:resume)

              instance.resume

              expect(resume_service).to have_received(:resume).once
            end
          end
        end
      end
    end
  end
end
