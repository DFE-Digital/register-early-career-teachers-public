describe Events::TransitionDescription do
  it "describes a transition from something to something else" do
    attribute_name = "induction_status"
    initial_value = "NotStarted"
    transitioned_to_value = "InProgress"

    description = Events::TransitionDescription.for(
      attribute_name,
      from: initial_value,
      to: transitioned_to_value
    )

    expect(description)
      .to eq("Induction status changed from 'NotStarted' to 'InProgress'")
  end

  it "describes a transition from something to nothing" do
    attribute_name = "induction_status"
    initial_value = "InProgress"
    transitioned_to_value = nil

    description = Events::TransitionDescription.for(
      attribute_name,
      from: initial_value,
      to: transitioned_to_value
    )

    expect(description).to eq("Induction status 'InProgress' removed")
  end

  it "describes a transition from nothing to something" do
    attribute_name = "induction_status"
    initial_value = nil
    transitioned_to_value = "InProgress"

    description = Events::TransitionDescription.for(
      attribute_name,
      from: initial_value,
      to: transitioned_to_value
    )

    expect(description).to eq("Induction status set to 'InProgress'")
  end

  it "describes a transition from nothing to nothing" do
    attribute_name = "induction_status"
    initial_value = nil
    transitioned_to_value = nil

    description = Events::TransitionDescription.for(
      attribute_name,
      from: initial_value,
      to: transitioned_to_value
    )

    expect(description).to eq("Induction status is not set")
  end

  it "describes a transition that hasn't changed" do
    attribute_name = "induction_status"
    initial_value = "InProgress"
    transitioned_to_value = "InProgress"

    description = Events::TransitionDescription.for(
      attribute_name,
      from: initial_value,
      to: transitioned_to_value
    )

    expect(description).to eq("Induction status 'InProgress' unchanged")
  end

  it "describes a transition with formatted dates" do
    attribute_name = "closed_on"
    initial_value = nil
    transitioned_to_value = Date.new(2025, 4, 1)

    description = Events::TransitionDescription.for(
      attribute_name,
      from: initial_value,
      to: transitioned_to_value
    )

    expect(description).to eq("Closed on set to '1 Apr 2025'")
  end
end
