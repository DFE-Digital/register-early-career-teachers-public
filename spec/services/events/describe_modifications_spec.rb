describe Events::DescribeModifications do
  context 'when the website field is added' do
    it %(is: Website set to 'www.website.com') do
      school = create(:gias_school, website: nil)
      school.assign_attributes(website: 'www.school.com')
      description_of_changes = Events::DescribeModifications.new(school.changes).describe

      expect(description_of_changes).to eql([%(Website set to 'www.school.com')])
    end
  end

  context 'when the website field is removed' do
    it %(is: Website 'www.school.com' removed) do
      school = create(:gias_school, website: 'www.school.com')
      school.assign_attributes(website: '')
      description_of_changes = Events::DescribeModifications.new(school.changes).describe

      expect(description_of_changes).to eql([%(Website 'www.school.com' removed)])
    end
  end

  context 'when both TRS first and last names are updated' do
    let(:description_of_changes) do
      teacher = create(:teacher, trs_first_name: 'Maurice', trs_last_name: 'Micklewhite')
      teacher.assign_attributes(trs_first_name: 'Michael', trs_last_name: 'Caine')
      Events::DescribeModifications.new(teacher.changes).describe
    end

    it %(includes: TRS first name changed from 'Maurice' to 'Michael') do
      expect(description_of_changes).to include(%(TRS first name changed from 'Maurice' to 'Michael'))
    end

    it %(includes: TRS last name changed from 'Micklewhite' to 'Caine') do
      expect(description_of_changes).to include(%(TRS last name changed from 'Micklewhite' to 'Caine'))
    end
  end

  context 'when a date is changed' do
    it %(it is formatted in the GOV.UK short date style: Closed on set to '24 Jan 2025') do
      school = create(:gias_school, closed_on: nil)
      school.assign_attributes(closed_on: Date.new(2025, 1, 24))
      description_of_changes = Events::DescribeModifications.new(school.changes).describe

      expect(description_of_changes).to eql([%(Closed on set to '24 Jan 2025')])
    end
  end
end
