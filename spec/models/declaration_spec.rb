describe Declaration do
  describe "associations" do
    it { is_expected.to belong_to(:training_period) }
    it { is_expected.to have_many(:statement_line_items).class_name("Statement::LineItem") }
  end

  describe "validation" do
    let(:declaration_types) { %w[started retained-1 retained-2 retained-3 retained-4 completed extended-1 extended-2 extended-3] }

    it { is_expected.to validate_presence_of(:training_period).with_message("Choose a training period") }
    it { is_expected.to validate_inclusion_of(:declaration_type).in_array(declaration_types).with_message("Choose a valid declaration type") }
  end
end
