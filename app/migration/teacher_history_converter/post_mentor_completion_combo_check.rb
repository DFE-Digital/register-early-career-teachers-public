## This checks if we should build training_periods for a mentor
#  beyond the mentor completion date for a given combo of attributes
#  Typically these are ERO mentors that have declarations that we need
#  to preserve, despite not being eligible for training.
class TeacherHistoryConverter::PostMentorCompletionComboCheck
  def keep?(profile_id:, lead_provider_id:, cohort_year:)
    combos_to_keep.find {
      it[:participant_profile_id] == profile_id &&
        it[:lead_provider_id] == lead_provider_id &&
        it[:cohort_year] == cohort_year
    }.present?
  end

private

  def combos_to_keep
    @combos_to_keep ||= make_combos_table
  end

  def make_combos_table
    keys = %i[participant_profile_id lead_provider_id cohort_year]
    [
      ["01753148-3f33-4f03-a1e5-6a4ef5392a77", "99317668-2942-4292-a895-fdb075af067b", 2021],
      ["11aa3216-a030-4251-bc35-cc56fb2875c6", "da470c27-05a6-4f5b-b9a9-58b04bfcc408", 2021],
      ["18a73f5d-89e9-4bc5-8238-37ff7383e65a", "99317668-2942-4292-a895-fdb075af067b", 2021],
      ["243aa55c-6b83-4b1c-b74e-0d05111169e8", "99317668-2942-4292-a895-fdb075af067b", 2021],
      ["288c3909-0baa-464b-a456-6f86701c9a4e", "3d7d8c90-a5a3-4838-84b2-563092bf87ee", 2021],
      ["2b3fba6b-4af2-46bb-8af8-c471a371cc56", "99317668-2942-4292-a895-fdb075af067b", 2021],
      ["2f975c0f-64b1-4640-93f2-9d94603f6454", "3d7d8c90-a5a3-4838-84b2-563092bf87ee", 2021],
      ["3349a615-cd08-426b-8688-71df763d326a", "3d7d8c90-a5a3-4838-84b2-563092bf87ee", 2021],
      ["3eea93d0-bf80-47ac-9dd8-d147de26d25f", "99317668-2942-4292-a895-fdb075af067b", 2022],
      ["6004d9ad-7bab-48bf-beda-6d40feab03d6", "c3bc3cee-a636-42d6-8324-c033a6c38d31", 2021],
      ["62193d98-201c-41fb-a54e-18ad13a56723", "3d7d8c90-a5a3-4838-84b2-563092bf87ee", 2021],
      ["67b2d9c6-c081-4258-b654-27ede6406f5c", "3d7d8c90-a5a3-4838-84b2-563092bf87ee", 2021],
      ["6efeb3a3-bd63-43fb-9e46-ee1b4ca435da", "99317668-2942-4292-a895-fdb075af067b", 2021],
      ["7d6e07d3-e802-402d-980c-abadd35f4fb7", "99317668-2942-4292-a895-fdb075af067b", 2021],
      ["83159aa9-c1b5-40c9-aa2e-5ebf5ca8ff97", "3d7d8c90-a5a3-4838-84b2-563092bf87ee", 2021],
      ["a10a57fc-a7dd-4329-868e-c1811704c7a0", "99317668-2942-4292-a895-fdb075af067b", 2021],
      ["d620fb7c-722b-49e7-b254-2f479aeb1a56", "99317668-2942-4292-a895-fdb075af067b", 2021],
      ["e4820449-5edb-4b42-b8c4-3eb68303dd5f", "99317668-2942-4292-a895-fdb075af067b", 2021],
      ["eecdaeca-801f-497e-87aa-b19f34ffb30d", "99317668-2942-4292-a895-fdb075af067b", 2021],
      ["f01482ec-fe33-4a41-83ef-27ae4dcb7e33", "c3bc3cee-a636-42d6-8324-c033a6c38d31", 2021],
      ["fafff34a-b37b-4920-960e-e03c1b48b481", "99317668-2942-4292-a895-fdb075af067b", 2021],
      ["ee23031b-723b-41a4-8ce3-5dc7f3b7d034", "c3bc3cee-a636-42d6-8324-c033a6c38d31", 2021],
      ["b649a5e0-c002-4212-8719-3be08ad61c05", "c3bc3cee-a636-42d6-8324-c033a6c38d31", 2021],
    ].map do |row|
      keys.zip(row).to_h
    end
  end
end
