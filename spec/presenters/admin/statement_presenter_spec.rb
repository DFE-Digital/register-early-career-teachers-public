describe Admin::StatementPresenter do
  subject { Admin::StatementPresenter.new(statement) }

  describe '#month_and_year' do
    let(:statement) { FactoryBot.build(:statement, month: 6, year: 2023) }

    it 'returns the month name and year in a string' do
      expect(subject.month_and_year).to eql('June 2023')
    end

    context 'when the month is invalid' do
      let(:statement) { FactoryBot.build(:statement, month: 13, year: 2023) }

      it 'raises an IndexError' do
        expect { subject.month_and_year }.to raise_error(IndexError)
      end
    end
  end

  describe '#status_tag_kwargs' do
    context 'when open' do
      let(:statement) { FactoryBot.build(:statement, :open) }

      it 'is blue and Open' do
        expect(subject.status_tag_kwargs).to eql({ colour: 'blue', text: 'Open' })
      end
    end

    context 'when payable' do
      let(:statement) { FactoryBot.build(:statement, :payable) }

      it 'is yellow and Payable' do
        expect(subject.status_tag_kwargs).to eql({ colour: 'yellow', text: 'Payable' })
      end
    end

    context 'when paid' do
      let(:statement) { FactoryBot.build(:statement, :paid) }

      it 'is green and Paid' do
        expect(subject.status_tag_kwargs).to eql({ colour: 'green', text: 'Paid' })
      end
    end

    context 'when unrecognised' do
      let(:statement) { FactoryBot.build(:statement, status: 'bad_state') }

      it 'raises an IndexError' do
        expect { subject.status_tag_kwargs }.to raise_error(IndexError)
      end
    end
  end

  describe '#page_title' do
    let(:lead_provider) { FactoryBot.build(:lead_provider, name: "Some LP") }
    let(:active_lead_provider) { FactoryBot.build(:active_lead_provider, lead_provider:) }
    let(:statement) { FactoryBot.build(:statement, active_lead_provider:, month: 5, year: 2023) }

    it 'returns the lead provider, month and year in a string' do
      expect(subject.page_title).to eql('Some LP - May 2023')
    end
  end

  describe '#lead_provider_name' do
    let(:lead_provider) { FactoryBot.build(:lead_provider, name: "Some LP") }
    let(:active_lead_provider) { FactoryBot.build(:active_lead_provider, lead_provider:) }
    let(:statement) { FactoryBot.build(:statement, active_lead_provider:) }

    it 'returns the lead provider name' do
      expect(subject.lead_provider_name).to eql('Some LP')
    end
  end

  describe '#registration_period_year' do
    let(:registration_period) { FactoryBot.build(:registration_period, year: 2022) }
    let(:active_lead_provider) { FactoryBot.build(:active_lead_provider, registration_period:) }
    let(:statement) { FactoryBot.build(:statement, active_lead_provider:) }

    it 'returns the lead provider name' do
      expect(subject.registration_period_year).to eql('2022')
    end
  end

  describe '#formatted_deadline_date' do
    let(:statement) { FactoryBot.build(:statement, deadline_date: Date.new(2024, 1, 1)) }

    it 'formats the deadline date in the GOV.UK style' do
      expect(subject.formatted_deadline_date).to eq('1 January 2024')
    end
  end

  describe '#formatted_payment_date' do
    let(:statement) { FactoryBot.build(:statement, deadline_date: Date.new(2025, 2, 2)) }

    it 'formats the payment date in the GOV.UK style' do
      expect(subject.formatted_deadline_date).to eq('2 February 2025')
    end
  end
end
