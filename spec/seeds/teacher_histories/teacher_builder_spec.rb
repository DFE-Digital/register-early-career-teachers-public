describe TeacherHistories::TeacherBuilder do
  let(:trn) { "1122334" }
  let(:trs_first_name) { "Clark" }
  let(:trs_last_name) { "Gable" }
  let(:full_name) { "#{trs_first_name} #{trs_last_name}" }

  describe ".teacher" do
    subject do
      TeacherHistories::TeacherBuilder.teacher(trn, full_name)
    end

    it "creates a teacher record" do
      expect(subject).to be_persisted
    end

    it "sets the TRN" do
      expect(subject.trn).to eql(trn)
    end

    it "sets the first name" do
      expect(subject.trs_first_name).to eql(trs_first_name)
    end

    it "sets the last name" do
      expect(subject.trs_last_name).to eql(trs_last_name)
    end

    context "when traits are provided" do
      subject { TeacherHistories::TeacherBuilder.teacher(trn, full_name, :with_realistic_name) }

      it "passes the trait on to the factory" do
        allow(FactoryBot).to receive(:build).and_call_original

        subject

        expect(FactoryBot).to have_received(:build).with(:teacher, :with_realistic_name, any_args)
      end
    end

    context "when attributes are overridden" do
      subject { TeacherHistories::TeacherBuilder.teacher(trn, full_name, trs_last_name: "Middleton") }

      it "passes the keyword arguments to the factory" do
        allow(FactoryBot).to receive(:build).and_call_original

        subject

        expect(FactoryBot).to have_received(:build).with(:teacher, trn:, trs_first_name: "Clark", trs_last_name: "Middleton")
      end
    end

    context "when a block is provided" do
      describe "building induction_periods" do
        context "when ongoing" do
          before do
            ab_one = FactoryBot.create(:appropriate_body_period)

            TeacherHistories::TeacherBuilder.teacher(trn, full_name) do
              induction_period(ab_one, "2024-01-01")
            end
          end

          it "adds a induction_period to the teacher" do
            expect(subject.induction_periods.count).to be(1)
          end

          it "the induction_period has no end date" do
            expect(subject.induction_periods.last.finished_on).to be_nil
          end
        end

        context "when there is a finish date" do
          before do
            ab_one = FactoryBot.create(:appropriate_body_period)

            TeacherHistories::TeacherBuilder.teacher(trn, full_name) do
              induction_period(ab_one, "2024-01-01 -> 2025-02-02")
            end
          end

          it "adds a induction_period to the teacher" do
            expect(subject.induction_periods.count).to be(1)
          end

          it "the induction_period has no end date" do
            expect(subject.induction_periods.last.finished_on).to eql(Date.new(2025, 2, 2))
          end
        end
      end

      describe "building mentor_at_school_periods" do
        context "when ongoing" do
          before do
            school_one = FactoryBot.create(:school)

            TeacherHistories::TeacherBuilder.teacher(trn, full_name) do
              mentor_at_school_period(school_one, "2024-01-01")
            end
          end

          it "adds a mentor_at_school_period to the teacher" do
            expect(subject.mentor_at_school_periods.count).to be(1)
          end

          it "the mentor_at_school_period has no end date" do
            expect(subject.mentor_at_school_periods.last.finished_on).to be_nil
          end
        end

        context "when there is a finish date" do
          before do
            school_one = FactoryBot.create(:school)

            TeacherHistories::TeacherBuilder.teacher(trn, full_name) do
              mentor_at_school_period(school_one, "2024-01-01 -> 2025-02-02")
            end
          end

          it "adds a mentor_at_school_period to the teacher" do
            expect(subject.mentor_at_school_periods.count).to be(1)
          end

          it "the mentor_at_school_period has no end date" do
            expect(subject.mentor_at_school_periods.last.finished_on).to eql(Date.new(2025, 2, 2))
          end
        end
      end

      describe "building ect_at_school_periods" do
        context "when ongoing" do
          before do
            school_one = FactoryBot.create(:school)

            TeacherHistories::TeacherBuilder.teacher(trn, full_name) do
              ect_at_school_period(school_one, "2024-01-01")
            end
          end

          it "adds a ect_at_school_period to the teacher" do
            expect(subject.ect_at_school_periods.count).to be(1)
          end

          it "the ect_at_school_period has no end date" do
            expect(subject.ect_at_school_periods.last.finished_on).to be_nil
          end
        end

        context "when there is a finish date" do
          before do
            school_one = FactoryBot.create(:school)

            TeacherHistories::TeacherBuilder.teacher(trn, full_name) do
              ect_at_school_period(school_one, "2024-01-01 -> 2025-03-03")
            end
          end

          it "adds a ect_at_school_period to the teacher" do
            expect(subject.ect_at_school_periods.count).to be(1)
          end

          it "the ect_at_school_period has no end date" do
            expect(subject.ect_at_school_periods.last.finished_on).to eql(Date.new(2025, 3, 3))
          end
        end
      end
    end
  end
end
