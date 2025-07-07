RSpec.describe 'Some Migrator' do
  it 'creates a School record in the ecf2 database' do
    expect { create(:school) }.to change(School, :count).by(1)
  end

  it 'create a School record in the ecf database' do
    expect { create(:ecf_migration_school) }.to change(Migration::School, :count).by(1)
  end
end
