RSpec.describe Teachers::UndoRegistration do
  let(:author) { Events::SystemAuthor.new }

  describe "#undo!" do
    subject(:undo_registration) do
      described_class.new(
        author:,
        at_school_period:,
        reason: :registered_in_error
      ).undo!
    end

    context "when the participant has billable declarations" do
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing) }
      let(:at_school_period) { ect_at_school_period }
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

        it "finishes the relevant periods" do
          expect_periods_to_be_finished(ect_at_school_period:, training_period:, mentorship_period:)
        end

        it "does not delete the relevant periods" do
          expect_periods_not_to_be_deleted(ect_at_school_period:, training_period:, mentorship_period:)
        end

        it "does not anonymise the teacher" do
          undo_registration
          teacher = ect_at_school_period.teacher.reload
          expect(teacher.trs_first_name).to be_present
          expect(teacher.trs_last_name).to be_present
        end

        it "does not set anonymisation_reason" do
          undo_registration
          expect(ect_at_school_period.teacher.reload.anonymisation_reason).to be_nil
        end

        it "does not set anonymised_at" do
          undo_registration
          expect(ect_at_school_period.teacher.reload.anonymised_at).to be_nil
        end

        it "records an undo registration event" do
          expect(Events::Record).to receive(:record_undo_registration_event!)
            .with(author:, teacher: ect_at_school_period.teacher, reason: :registered_in_error)
          undo_registration
        end
      end

      context "with a payable declaration" do
        let!(:declaration) { FactoryBot.create(:declaration, :payable, training_period:) }

        it "finishes the relevant periods" do
          expect_periods_to_be_finished(ect_at_school_period:, training_period:, mentorship_period:)
        end

        it "does not delete the relevant periods" do
          expect_periods_not_to_be_deleted(ect_at_school_period:, training_period:, mentorship_period:)
        end
      end

      context "with a paid declaration" do
        let!(:declaration) { FactoryBot.create(:declaration, :paid, training_period:) }

        it "finishes the relevant periods" do
          expect_periods_to_be_finished(ect_at_school_period:, training_period:, mentorship_period:)
        end

        it "does not delete the relevant periods" do
          expect_periods_not_to_be_deleted(ect_at_school_period:, training_period:, mentorship_period:)
        end
      end
    end

    context "when the participant has refundable declarations" do
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing) }
      let(:at_school_period) { ect_at_school_period }
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

        it "finishes the relevant periods" do
          expect_periods_to_be_finished(ect_at_school_period:, training_period:, mentorship_period:)
        end

        it "does not delete the relevant periods" do
          expect_periods_not_to_be_deleted(ect_at_school_period:, training_period:, mentorship_period:)
        end

        it "does not anonymise the teacher" do
          undo_registration
          teacher = ect_at_school_period.teacher.reload
          expect(teacher.trs_first_name).to be_present
          expect(teacher.trs_last_name).to be_present
        end

        it "does not set anonymisation_reason" do
          undo_registration
          expect(ect_at_school_period.teacher.reload.anonymisation_reason).to be_nil
        end

        it "does not set anonymised_at" do
          undo_registration
          expect(ect_at_school_period.teacher.reload.anonymised_at).to be_nil
        end

        it "records an undo registration event" do
          expect(Events::Record).to receive(:record_undo_registration_event!)
            .with(author:, teacher: ect_at_school_period.teacher, reason: :registered_in_error)
          undo_registration
        end
      end

      context "with a clawed_back declaration" do
        let!(:declaration) { FactoryBot.create(:declaration, :clawed_back, training_period:) }

        it "finishes the relevant periods" do
          expect_periods_to_be_finished(ect_at_school_period:, training_period:, mentorship_period:)
        end

        it "does not delete the relevant periods" do
          expect_periods_not_to_be_deleted(ect_at_school_period:, training_period:, mentorship_period:)
        end
      end
    end

    context "when the participant has no billable or refundable declarations" do
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing) }
      let(:at_school_period) { ect_at_school_period }
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
        it "deletes the relevant periods" do
          expect_periods_to_be_deleted(ect_at_school_period:, training_period:, mentorship_period:)
        end

        it "records an undo registration event" do
          expect(Events::Record).to receive(:record_undo_registration_event!)
            .with(author:, teacher: ect_at_school_period.teacher, reason: :registered_in_error)
          undo_registration
        end
      end

      context "with only a non-billable declaration" do
        let!(:declaration) { FactoryBot.create(:declaration, training_period:) }

        it "deletes the relevant periods" do
          expect_periods_to_be_deleted(ect_at_school_period:, training_period:, mentorship_period:)
        end
      end

      context "with only a voided declaration" do
        let!(:declaration) { FactoryBot.create(:declaration, :voided, training_period:) }

        it "deletes the relevant periods" do
          expect_periods_to_be_deleted(ect_at_school_period:, training_period:, mentorship_period:)
        end
      end

      context "when the teacher has an induction period" do
        let!(:induction_period) { FactoryBot.create(:induction_period, teacher: ect_at_school_period.teacher) }

        it "deletes the relevant periods" do
          expect_periods_to_be_deleted(ect_at_school_period:, training_period:, mentorship_period:)
        end

        it "does not anonymise the teacher" do
          undo_registration
          teacher = ect_at_school_period.teacher.reload
          expect(teacher.trs_first_name).to be_present
          expect(teacher.trs_last_name).to be_present
        end

        it "does not set anonymisation_reason" do
          undo_registration
          expect(ect_at_school_period.teacher.reload.anonymisation_reason).to be_nil
        end

        it "does not set anonymised_at" do
          undo_registration
          expect(ect_at_school_period.teacher.reload.anonymised_at).to be_nil
        end

        it "records an undo registration event" do
          expect(Events::Record).to receive(:record_undo_registration_event!)
            .with(author:, teacher: ect_at_school_period.teacher, reason: :registered_in_error)
          undo_registration
        end
      end

      context "when the teacher has another mentor registration" do
        let!(:other_mentor_at_school_period) do
          FactoryBot.create(:mentor_at_school_period, :ongoing, teacher: ect_at_school_period.teacher)
        end

        it "deletes only the targeted ECT registration" do
          undo_registration

          expect { ect_at_school_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { training_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { mentorship_period.reload }.to raise_error(ActiveRecord::RecordNotFound)

          expect { other_mentor_at_school_period.reload }.not_to raise_error
        end

        it "does not anonymise the teacher" do
          undo_registration

          teacher = ect_at_school_period.teacher.reload
          expect(teacher.trs_first_name).to be_present
          expect(teacher.trs_last_name).to be_present
          expect(teacher.anonymisation_reason).to be_nil
          expect(teacher.anonymised_at).to be_nil
        end
      end

      context "when the teacher has another ECT registration" do
        let!(:other_ect_at_school_period) do
          FactoryBot.create(
            :ect_at_school_period,
            teacher: ect_at_school_period.teacher,
            started_on: 2.years.ago.to_date,
            finished_on: 1.year.ago.to_date
          )
        end

        it "deletes only the targeted ECT registration" do
          undo_registration

          expect { ect_at_school_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { training_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { mentorship_period.reload }.to raise_error(ActiveRecord::RecordNotFound)

          expect { other_ect_at_school_period.reload }.not_to raise_error
        end

        it "does not anonymise the teacher" do
          undo_registration

          teacher = ect_at_school_period.teacher.reload
          expect(teacher.trs_first_name).to be_present
          expect(teacher.trs_last_name).to be_present
          expect(teacher.anonymisation_reason).to be_nil
          expect(teacher.anonymised_at).to be_nil
        end
      end

      context "when the teacher has no induction period" do
        it "keeps the teacher record" do
          teacher = ect_at_school_period.teacher
          undo_registration
          expect { teacher.reload }.not_to raise_error
        end

        it "preserves api_id" do
          teacher = ect_at_school_period.teacher
          original = teacher.api_id
          undo_registration
          expect(teacher.reload.api_id).to eq(original)
        end

        it "preserves api_ect_training_record_id" do
          teacher = ect_at_school_period.teacher
          original = teacher.api_ect_training_record_id
          undo_registration
          expect(teacher.reload.api_ect_training_record_id).to eq(original)
        end

        it "preserves api_mentor_training_record_id" do
          teacher = ect_at_school_period.teacher
          original = teacher.api_mentor_training_record_id
          undo_registration
          expect(teacher.reload.api_mentor_training_record_id).to eq(original)
        end

        it "anonymises the teacher" do
          undo_registration
          teacher = ect_at_school_period.teacher.reload
          expect(teacher.trs_first_name).to be_nil
          expect(teacher.trs_last_name).to be_nil
          expect(teacher.corrected_name).to be_nil
          expect(teacher.trn).to be_nil
        end

        it "sets the anonymisation reason to registered_in_error" do
          undo_registration
          expect(ect_at_school_period.teacher.reload.anonymisation_reason).to eq("registered_in_error")
        end

        it "sets anonymised_at" do
          freeze_time do
            undo_registration
            expect(ect_at_school_period.teacher.reload.anonymised_at).to eq(Time.zone.now)
          end
        end

        it "sets trnless to true" do
          undo_registration
          expect(ect_at_school_period.teacher.reload.trnless).to be(true)
        end
      end
    end

    context "when undoing a mentor registration" do
      let(:mentor_at_school_period) { FactoryBot.create(:mentor_at_school_period, :ongoing) }
      let(:at_school_period) { mentor_at_school_period }
      let!(:training_period) { FactoryBot.create(:training_period, :for_mentor, :ongoing, mentor_at_school_period:) }

      context "with no declarations" do
        it "only undoes the targeted registration" do
          undo_registration
          expect { mentor_at_school_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { training_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "when the teacher has another ECT registration" do
        let!(:other_ect_at_school_period) do
          FactoryBot.create(:ect_at_school_period, :ongoing, teacher: mentor_at_school_period.teacher)
        end

        it "deletes only the targeted mentor registration" do
          undo_registration

          expect { mentor_at_school_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { training_period.reload }.to raise_error(ActiveRecord::RecordNotFound)

          expect { other_ect_at_school_period.reload }.not_to raise_error
        end

        it "does not anonymise the teacher" do
          undo_registration

          teacher = mentor_at_school_period.teacher.reload
          expect(teacher.trs_first_name).to be_present
          expect(teacher.trs_last_name).to be_present
          expect(teacher.anonymisation_reason).to be_nil
          expect(teacher.anonymised_at).to be_nil
        end
      end

      context "when the teacher has another mentor registration" do
        let!(:other_mentor_at_school_period) do
          FactoryBot.create(:mentor_at_school_period, :ongoing, teacher: mentor_at_school_period.teacher)
        end

        it "deletes only the targeted mentor registration" do
          undo_registration

          expect { mentor_at_school_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { training_period.reload }.to raise_error(ActiveRecord::RecordNotFound)

          expect { other_mentor_at_school_period.reload }.not_to raise_error
        end

        it "does not anonymise the teacher" do
          undo_registration

          teacher = mentor_at_school_period.teacher.reload
          expect(teacher.trs_first_name).to be_present
          expect(teacher.trs_last_name).to be_present
          expect(teacher.anonymisation_reason).to be_nil
          expect(teacher.anonymised_at).to be_nil
        end
      end
    end

    context "when the teacher has previous legitimate registrations" do
      let(:teacher) { FactoryBot.create(:teacher) }
      let(:legitimate_period) { FactoryBot.create(:ect_at_school_period, :finished, teacher:) }
      let!(:legitimate_training_period) { FactoryBot.create(:training_period, :for_ect, :finished, ect_at_school_period: legitimate_period) }
      let(:erroneous_period) { FactoryBot.create(:ect_at_school_period, :ongoing, teacher:, started_on: legitimate_period.finished_on + 1.day) }
      let!(:erroneous_training_period) { FactoryBot.create(:training_period, :for_ect, :ongoing, ect_at_school_period: erroneous_period) }
      let(:at_school_period) { erroneous_period }

      it "only undoes the targeted registration" do
        undo_registration
        expect { erroneous_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { legitimate_period.reload }.not_to raise_error
        expect { legitimate_training_period.reload }.not_to raise_error
      end
    end

    context "when an error occurs during undoing the registration" do
      let(:ect_at_school_period) { FactoryBot.create(:ect_at_school_period, :ongoing) }
      let(:at_school_period) { ect_at_school_period }
      let!(:training_period) { FactoryBot.create(:training_period, :for_ect, :ongoing, ect_at_school_period:) }

      it "rolls back all changes" do
        allow(Events::Record).to receive(:record_undo_registration_event!).and_raise(StandardError)
        expect { undo_registration }.to raise_error(StandardError)
        expect { ect_at_school_period.reload }.not_to raise_error
        expect { training_period.reload }.not_to raise_error
      end
    end

    def expect_periods_to_be_finished(ect_at_school_period:, training_period:, mentorship_period:)
      freeze_time do
        undo_registration
        expect(ect_at_school_period.reload.finished_on).to eq(Time.zone.today)
        expect(training_period.reload.finished_on).to eq(Time.zone.today)
        expect(mentorship_period.reload.finished_on).to eq(Time.zone.today)
      end
    end

    def expect_periods_not_to_be_deleted(ect_at_school_period:, training_period:, mentorship_period:)
      undo_registration
      expect { ect_at_school_period.reload }.not_to raise_error
      expect { training_period.reload }.not_to raise_error
      expect { mentorship_period.reload }.not_to raise_error
    end

    def expect_periods_to_be_deleted(ect_at_school_period:, training_period:, mentorship_period:)
      undo_registration
      expect { ect_at_school_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { training_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { mentorship_period.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
