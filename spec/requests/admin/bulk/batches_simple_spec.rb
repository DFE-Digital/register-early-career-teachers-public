RSpec.describe "Admin Bulk Batches Routing", type: :request do
  describe "routing paths" do
    it "index path exists" do
      expect(admin_bulk_batches_path).to eq("/admin/bulk/batches")
    end

    it "show path exists with id" do
      expect(admin_bulk_batch_path(123)).to eq("/admin/bulk/batches/123")
    end
  end
end
