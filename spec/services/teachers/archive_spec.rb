RSpec.describe Teachers::Archive do
  let(:author) { Events::SystemAuthor.new }

  describe "#archive" do
    subject(:archive) do
      described_class.new(
        author:,
        period:,
        reason: :registered_in_error
      ).archive
    end

    context "when the participant has billable declarations" do
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing) }
      let(:period) { ect_at_school_period }
      let!(:training_period) { FactoryBot.create(:training_period, :for_ect, :ongoing, ect_at_school_period:) }
      let(:mentor_at_school_period) do
        FactoryBot.create(:mentor_at_school_period, :ongoing, started_on: ect_at_school_period.started_on, school: ect_at_school_period.school)
      end
      let!(:mentorship_period) do
        FactoryBot.create(
          :mentorship_period,
          mentee: ect_at_school_period,
          mentor: mentor_at_school_period,
          started_on: ect_at_school_period.started_on,
          finished_on: nil
        )
      end

      context "with an eligible declaration" do
        let!(:declaration) { FactoryBot.create(:declaration, :eligible, training_period:) }

        it "sets finished_on to today on the relevant school period" do
          freeze_time do
            archive
            expect(ect_at_school_period.reload.finished_on).to eq(Time.zone.today)
          end
        end

        it "sets finished_on to today on the relevant training period" do
          freeze_time do
            archive
            expect(training_period.reload.finished_on).to eq(Time.zone.today)
          end
        end

        it "sets finished_on to today on relevant mentorship periods" do
          freeze_time do
            archive
            expect(mentorship_period.reload.finished_on).to eq(Time.zone.today)
          end
        end

        it "does not delete the relevant periods" do
          archive
          expect { ect_at_school_period.reload }.not_to raise_error
          expect { training_period.reload }.not_to raise_error
          expect { mentorship_period.reload }.not_to raise_error
        end

        it "does not anonymise the teacher" do
          archive
          teacher = ect_at_school_period.teacher.reload
          expect(teacher.trs_first_name).to be_present
          expect(teacher.trs_last_name).to be_present
        end

        it "does not set archived_reason" do
          archive
          expect(ect_at_school_period.teacher.reload.archived_reason).to be_nil
        end

        it "does not set archived_at" do
          archive
          expect(ect_at_school_period.teacher.reload.archived_at).to be_nil
        end

        it "records an archive event" do
          expect(Events::Record).to receive(:record_teacher_archived_event!)
            .with(author:, teacher: ect_at_school_period.teacher, reason: :registered_in_error)
          archive
        end
      end

      context "with a payable declaration" do
        let!(:declaration) { FactoryBot.create(:declaration, :payable, training_period:) }

        it "sets finished_on to today on the relevant periods" do
          freeze_time do
            archive

            expect(ect_at_school_period.reload.finished_on).to eq(Time.zone.today)
            expect(training_period.reload.finished_on).to eq(Time.zone.today)
            expect(mentorship_period.reload.finished_on).to eq(Time.zone.today)
          end
        end

        it "does not delete the relevant periods" do
          archive
          expect { ect_at_school_period.reload }.not_to raise_error
          expect { training_period.reload }.not_to raise_error
          expect { mentorship_period.reload }.not_to raise_error
        end
      end

      context "with a paid declaration" do
        let!(:declaration) { FactoryBot.create(:declaration, :paid, training_period:) }

        it "does not delete the relevant periods" do
          archive
          expect { ect_at_school_period.reload }.not_to raise_error
          expect { training_period.reload }.not_to raise_error
          expect { mentorship_period.reload }.not_to raise_error
        end

        it "sets finished_on to today on the relevant periods" do
          freeze_time do
            archive

            expect(ect_at_school_period.reload.finished_on).to eq(Time.zone.today)
            expect(training_period.reload.finished_on).to eq(Time.zone.today)
            expect(mentorship_period.reload.finished_on).to eq(Time.zone.today)
          end
        end
      end
    end

    context "when the participant has refundable declarations" do
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing) }
      let(:period) { ect_at_school_period }
      let!(:training_period) { FactoryBot.create(:training_period, :for_ect, :ongoing, ect_at_school_period:) }
      let(:mentor_at_school_period) do
        FactoryBot.create(:mentor_at_school_period, :ongoing, started_on: ect_at_school_period.started_on, school: ect_at_school_period.school)
      end
      let!(:mentorship_period) do
        FactoryBot.create(
          :mentorship_period,
          mentee: ect_at_school_period,
          mentor: mentor_at_school_period,
          started_on: ect_at_school_period.started_on,
          finished_on: nil
        )
      end

      context "with an awaiting_clawback declaration" do
        let!(:declaration) { FactoryBot.create(:declaration, :awaiting_clawback, training_period:) }

        it "sets finished_on to today on the relevant periods" do
          freeze_time do
            archive
            expect(ect_at_school_period.reload.finished_on).to eq(Time.zone.today)
            expect(training_period.reload.finished_on).to eq(Time.zone.today)
            expect(mentorship_period.reload.finished_on).to eq(Time.zone.today)
          end
        end

        it "does not delete the relevant periods" do
          archive
          expect { ect_at_school_period.reload }.not_to raise_error
          expect { training_period.reload }.not_to raise_error
          expect { mentorship_period.reload }.not_to raise_error
        end

        it "does not anonymise the teacher" do
          archive
          teacher = ect_at_school_period.teacher.reload
          expect(teacher.trs_first_name).to be_present
          expect(teacher.trs_last_name).to be_present
        end

        it "does not set archived_reason" do
          archive
          expect(ect_at_school_period.teacher.reload.archived_reason).to be_nil
        end

        it "does not set archived_at" do
          archive
          expect(ect_at_school_period.teacher.reload.archived_at).to be_nil
        end

        it "records an archive event" do
          expect(Events::Record).to receive(:record_teacher_archived_event!)
            .with(author:, teacher: ect_at_school_period.teacher, reason: :registered_in_error)
          archive
        end
      end

      context "with a clawed_back declaration" do
        let!(:declaration) { FactoryBot.create(:declaration, :clawed_back, training_period:) }

        it "does not delete the relevant periods" do
          archive
          expect { ect_at_school_period.reload }.not_to raise_error
          expect { training_period.reload }.not_to raise_error
          expect { mentorship_period.reload }.not_to raise_error
        end

        it "sets finished_on to today on the relevant periods" do
          freeze_time do
            archive

            expect(ect_at_school_period.reload.finished_on).to eq(Time.zone.today)
            expect(training_period.reload.finished_on).to eq(Time.zone.today)
            expect(mentorship_period.reload.finished_on).to eq(Time.zone.today)
          end
        end
      end
    end

    context "when the participant has no billable or refundable declarations" do
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing) }
      let(:period) { ect_at_school_period }
      let!(:training_period) { FactoryBot.create(:training_period, :for_ect, :ongoing, ect_at_school_period:) }
      let(:mentor_at_school_period) do
        FactoryBot.create(:mentor_at_school_period, :ongoing, started_on: ect_at_school_period.started_on, school: ect_at_school_period.school)
      end
      let!(:mentorship_period) do
        FactoryBot.create(
          :mentorship_period,
          mentee: ect_at_school_period,
          mentor: mentor_at_school_period,
          started_on: ect_at_school_period.started_on,
          finished_on: nil
        )
      end

      context "with no declarations" do
        it "deletes the relevant school period" do
          archive
          expect { ect_at_school_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "deletes the relevant training period" do
          archive
          expect { training_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "deletes relevant mentorship periods" do
          archive
          expect { mentorship_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "records an archive event" do
          expect(Events::Record).to receive(:record_teacher_archived_event!)
            .with(author:, teacher: ect_at_school_period.teacher, reason: :registered_in_error)
          archive
        end
      end

      context "with only a non-billable declaration" do
        let!(:declaration) { FactoryBot.create(:declaration, training_period:) }

        it "deletes the relevant periods" do
          archive
          expect { ect_at_school_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { training_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { mentorship_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "with only a voided declaration" do
        let!(:declaration) { FactoryBot.create(:declaration, :voided, training_period:) }

        it "deletes the relevant periods" do
          archive
          expect { ect_at_school_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { training_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { mentorship_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "when the teacher has an induction period" do
        let!(:induction_period) { FactoryBot.create(:induction_period, teacher: ect_at_school_period.teacher) }

        it "does not anonymise the teacher" do
          archive
          teacher = ect_at_school_period.teacher.reload
          expect(teacher.trs_first_name).to be_present
          expect(teacher.trs_last_name).to be_present
        end

        it "does not set archived_reason" do
          archive
          expect(ect_at_school_period.teacher.reload.archived_reason).to be_nil
        end

        it "does not set archived_at" do
          archive
          expect(ect_at_school_period.teacher.reload.archived_at).to be_nil
        end

        it "deletes the relevant school period" do
          archive
          expect { ect_at_school_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "deletes the relevant training period" do
          archive
          expect { training_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "deletes relevant mentorship periods" do
          archive
          expect { mentorship_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "records an archive event" do
          expect(Events::Record).to receive(:record_teacher_archived_event!)
            .with(author:, teacher: ect_at_school_period.teacher, reason: :registered_in_error)
          archive
        end
      end

      context "when the teacher has no induction period" do
        it "keeps the teacher record" do
          teacher = ect_at_school_period.teacher
          archive
          expect { teacher.reload }.not_to raise_error
        end

        it "preserves api_id" do
          teacher = ect_at_school_period.teacher
          original = teacher.api_id
          archive
          expect(teacher.reload.api_id).to eq(original)
        end

        it "preserves api_ect_training_record_id" do
          teacher = ect_at_school_period.teacher
          original = teacher.api_ect_training_record_id
          archive
          expect(teacher.reload.api_ect_training_record_id).to eq(original)
        end

        it "preserves api_mentor_training_record_id" do
          teacher = ect_at_school_period.teacher
          original = teacher.api_mentor_training_record_id
          archive
          expect(teacher.reload.api_mentor_training_record_id).to eq(original)
        end

        it "anonymises the teacher" do
          archive
          teacher = ect_at_school_period.teacher.reload
          expect(teacher.trs_first_name).to be_nil
          expect(teacher.trs_last_name).to be_nil
          expect(teacher.corrected_name).to be_nil
          expect(teacher.trn).to be_nil
        end

        it "sets the archive reason to registered_in_error" do
          archive
          expect(ect_at_school_period.teacher.reload.archived_reason).to eq("registered_in_error")
        end

        it "sets archived_at" do
          freeze_time do
            archive
            expect(ect_at_school_period.teacher.reload.archived_at).to eq(Time.zone.now)
          end
        end

        it "sets trnless to true" do
          archive
          expect(ect_at_school_period.teacher.reload.trnless).to be(true)
        end
      end
    end

    context "when archiving a mentor registration" do
      let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing) }
      let(:period) { mentor_at_school_period }
      let!(:training_period) { FactoryBot.create(:training_period, :for_mentor, :ongoing, mentor_at_school_period:) }

      context "with no declarations" do
        it "deletes the mentor registration" do
          archive
          expect { mentor_at_school_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { training_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context "when the teacher has previous legitimate registrations" do
      let(:teacher) { FactoryBot.create(:teacher) }
      let(:legitimate_period) { FactoryBot.create(:ect_at_school_period, :finished, teacher:) }
      let!(:legitimate_training_period) { FactoryBot.create(:training_period, :for_ect, :finished, ect_at_school_period: legitimate_period) }
      let(:erroneous_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, started_on: legitimate_period.finished_on + 1.day) }
      let!(:erroneous_training_period) { FactoryBot.create(:training_period, :for_ect, :ongoing, ect_at_school_period: erroneous_period) }
      let(:period) { erroneous_period }

      it "only archives the targeted registration" do
        archive
        expect { erroneous_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { legitimate_period.reload }.not_to raise_error
        expect { legitimate_training_period.reload }.not_to raise_error
      end
    end

    context "when an error occurs mid-archive" do
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing) }
      let(:period) { ect_at_school_period }
      let!(:training_period) { FactoryBot.create(:training_period, :for_ect, :ongoing, ect_at_school_period:) }

      it "rolls back all changes" do
        allow(Events::Record).to receive(:record_teacher_archived_event!).and_raise(StandardError)
        expect { archive }.to raise_error(StandardError)
        expect { ect_at_school_period.reload }.not_to raise_error
        expect { training_period.reload }.not_to raise_error
      end
    end
  end
end
