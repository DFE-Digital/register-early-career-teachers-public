describe Events::DescribeModifications do
  it 'converts a ActiveRecord changes to a human-readable list of changed fields' do
    teacher = FactoryBot.create(:teacher, trs_first_name: 'Maurice', trs_last_name: 'Micklewhite')

    teacher.assign_attributes(trs_first_name: 'Michael', trs_last_name: 'Caine')

    description_of_changes = Events::DescribeModifications.new(teacher.changes).describe

    expect(description_of_changes).to eql(
      ['TRS first name changed from Maurice to Michael',
       'TRS last name changed from Micklewhite to Caine']
    )
  end
end
