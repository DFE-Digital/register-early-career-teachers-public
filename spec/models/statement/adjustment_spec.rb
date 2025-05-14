describe Statement::Adjustment do
  describe "associations" do
    it { is_expected.to belong_to(:statement) }
  end
end
