---
title: School admins in Register early career teachers
---

This document covers how the new Register early career teachers service will work for school users.

In the service, we ask schools for information about early career teachers (ECTs) and their mentors so DfE can:

* make sure they’re trained as an early career teacher or a mentor
* send funding to schools to give them time off timetable for training or mentoring
* publish statistics on how early career teaching programmes are performing

These are the rules of how the service will work that we have determined so far. We’ll continue to add to this over time.

School users are also known as:

* school admins
* school induction tutors (SITs)
* school induction coordinators

## How the service works for schools

[Accessing the service](#accessing_the_service)

[Registering an early career teacher](#registering-an-early-career-teacher)

[Assigning a mentor to an early career teacher](#assigning_a_mentor)
 
 

<a id="accessing_the_service"></a>

## Accessing the service

### Getting access to the service via DfE Sign-in

For a school admin to get access to the service, they will need to use [DfE Sign in](https://services.signin.education.gov.uk/).

DfE Sign-in is how schools and other education organisations access DfE online services. We’ve decided to use it for Register ECTs because:

* schools use it for other services, and were getting confused in ECF1
* in research, most school users had an understanding of DfE Sign in
* access to the service historically worked through using info from Get information about schools, but many schools weren’t aware of this
* it still makes sure the person accessing the service actually works for the school by going through an approval process

You can read more about why we chose to do this in [our design history](https://teacher-cpd.design-history.education.gov.uk/ecf-v2/exploring-using-dfe-sign-in/).

To get access to the service, a school will need to request for approval. This is checked and actioned by whoever at their school has approval permissions. Once this is done, they will be able to sign into the service and view the records for their school.

### Number of users that can access the service

We will not limit the number of users per school. This means multiple people can get access, unlike in ECF1. Schools will manage the users who can access the service for their school themselves via DfE Sign In.

You can read more about [why we made this decision in our design history](https://teacher-cpd.design-history.education.gov.uk/ecf-v2/allowing-multiple-school-accounts/).

## Registering an early career teacher

### Finding an ECT’s record in the Teaching Record System

When a school registers an ECT, we need to find the ECT’s TRS record so that we can check they are a real person, that the school knows them and so that we can determine their eligibility for training.

To find an ECT’s teacher record, we need to check the Teaching Record System (TRS) API. The ECT needs a TRN and a teacher record to be eligible for training.

To do this, we ask for the ECT’s TRN and date of birth.

We should always ask for two fields of personal information before registering an ECT’s record. This is because we need to make sure the person registering the ECT actually knows that ECT. If we just ask for TRN, they could be entering a random number.

If we can’t find a matching TRN that exists, we tell the user the ECT’s teacher record cannot be found.

If we can find a record in the teaching record system (TRS) matching the ECT's TRN but not the provided date of birth, we ask for the ECT's national insurance number instead.

We do this because potentially the date of birth stored on the teacher’s record in the TRS is incorrect, or the one the school holds might be. It makes it more likely for the user to find the ECT’s teacher record and confirm they know them.

If we still cannot confirm the user knows both the TRN and either national insurance number or date of birth, we tell them the record cannot be found.

Neither date of birth or national insurance number should be stored longer-term in the Register ECTs service. It is just used for the initial finding and checking of an ECT’s record in the TRS. You can read more [about our reasoning for this here](https://teacher-cpd.design-history.education.gov.uk/ecf-v2/no-longer-storing-date-of-birth/).

### Checking the ECT is eligible to be registered for training

When an ECT is being registered for training, we should check if their record already exists in the Register ECTs service.

If the ECT being registered already exists as an ‘in progress’ or ‘completed’ ECT at their school, we should not let them progress with registration. This is because the ECT record already exists and we do not want duplicates. If the ECT has ‘left’ their school, we should still let them progress with registration, as the ECT may have returned.

At this stage, when we check the TRS for the existence of the ECT’s record, we also need to make sure the ECT:

* has not passed induction already
* has not failed induction already
* is not exempt from induction
  

Whilst an ECT needs qualified teaching status in order to be eligible for funding for training, we do allow them to be registered in advance without it. Similarly, an ECT needs an open induction period reported by an appropriate body to be eligible for funding for training, but they can be registered in advance without this.

This is because we know schools might want to register an ECT before they actually start working in a school. This might mean that ECT doesn’t always have QTS before they are registered for training.

### Registering an early career teacher who has been registered before at another school

We still need to define what happens here.

### Confirming or correcting an ECT’s name

Once we’ve decided the ECT can be added to the service, we play back the name from the TRA’s Teaching Record System to the user. This is so we can show them it’s linked to their teacher record and that they must be intending to register that person.

We give users the option to either:

* confirm the name is correct and continue
* correct the name and continue

We did this because:

* we know the name held in the TRS is often out of date
* we want lead providers to have correct contact details for ECTs
* we don’t want to block schools from registering someone because the name of the ECT may have been updated

If the name is corrected, we will continue to show the corrected name in the service from this point. We will continue to store the name from the TRS, so we can monitor if this feature is being used correctly, and it’s not being overwritten with names that are completely different.

You can read more about why we chose to change how an ECT’s name is gathered [in the design history entry here](https://teacher-cpd.design-history.education.gov.uk/ecf-v2/correcting-names/).

### Giving an ECT’s email address

The school user is asked for that ECT’s email address.

We tell them they can update the email at a later point. This is because we know sometimes school users register ECTs in advance, when their school email address might not be ready yet.

We check the email address given and make sure it doesn’t exist for an ongoing ECT or mentor record with a different TRN. This would mean any emails that are attached to an open `ect_at_school_period` or open `mentor_at_school_period`. This is because we shouldn’t have email addresses that are the same for entirely different people, when both are are still undergoing training.

This avoids a scenario where two different people are given the same email address. If their lead provider was the same, the lead provider would be unable to set them up with unique accounts for their learning platform.

In addition, it prevents us sending privacy notes or other communication intended for the other person.

We also make sure the email follows a correct format.

### Giving the school start date for an ECT

The school user is asked for the date when the ECT will start or started as an early career teacher.

We ask this question so we can get a better understanding of when the ECT is starting before we have the induction start date.

The school start date is important because:

* it informs lead providers of when the training should start for the ECT
* it alters what funding the ECT might be eligible for

You can read more about why we chose to add this question [in the design history entry here](https://teacher-cpd.design-history.education.gov.uk/ecf-v2/ects-start-date/).

We’ll update this later with more information on the validation and rules for the start date that can be given. 

### Giving an ECT’s working pattern

We always ask for the working pattern for an ECT so:

* the ECT can be onboarded to the correct kind of training with a lead provider
* the lead provider or delivery partner can enquire more with the school for part-time ECTs, to make sure they have all the information they need and are fully supported
* we better understand the kinds of ECTs undergoing training 

This question is new for Register early career teachers, so the working pattern field will not be populated for migrated records.

You can read more about why we chose to add this question [in the design history entry here](https://teacher-cpd.design-history.education.gov.uk/ecf-v2/asking-schools-whether-an-ect-is-full-or-part-time/).

### Generating an expected training start year

The expected training start year is generated from when the ECT is registered and when the school reports the ECT is starting. This is because if an ECT had started at a school in January 2024, which would be in the 2023 to 2024 academic year, but they’re only registered by the school in September 2024, they wouldn’t be starting with a lead provider for training until the 2024 to 2025 academic year. Essentially, training can’t be expected to start until they’re registered with DfE and have their details passed to a lead provider. 

Similarly, if an ECT is starting in October 2025, the 2025 to 2026 academic year, but is registered in April 2025, the 2024 to 2025 academic year, we would want to show them lead providers for the 2025 to 2026 academic year. Both pieces of information are needed to work out when realistically the ECT will be starting training, and therefore who will be a legitimate lead provider (or delivery partner) to work with them.

### Reusing previous programme details when registering an ECT

When ECTs are inducted and trained at a school, most of the time they have the same:

1. appropriate body
2. programme type (school-led or provider-led)
3. lead provider
4. delivery partner

Because of this, when schools register ECTs, we show them the programme choices used by their school previously, if they have registered an ECT before. This is so it speeds up schools being able to register ECTs efficiently, as they’ll often use the same information.

We would show programme details including appropriate body, programme type, lead provider and delivery partner if:

- there is a partnership between a school, lead provider and delivery partner for the academic year which matches the expected training start year of the ECT, and it was the information that was most recently used by the school when registering ECTs
- or, there is a partnership between a school, lead provider and delivery partner for a previous academic year which was most recently used by the school when registering ECTs

If the above is not the case, we would only show the appropriate body, programme type and lead provider that was most recently used. This is because we don’t want to ask schools for a delivery partner from scratch as it’s a question they find hard to answer and may give inaccurate information for. You can read more about why we decided to do this [in the design history entry here](https://teacher-cpd.design-history.education.gov.uk/ecf-v2/removing-the-delivery-partner-question/).

If a school user answers ‘yes’ to if they’re using previous programme details, it will take them straight to the check your answers page.

If they answer ‘no’, we’ll ask them all four questions for the ECT being registered again.

Typically, most schools also typically reuse these details across different academic years. When this changes, it’s  because the school has chosen to change how training and induction takes place for their ECTs or because they can no longer work with the same organisations they did before.

This may be because one of the organisations has stopped providing services in a role, a lead provider and delivery partner are no longer working together to deliver training. This means their ‘previously used choices’ are no longer valid options. This would typically happen when a school is registering an ECT in a new academic year for the first time.

This comes from when we expected the ECT to start training - their expected training start year, defined above. If the lead provider or delivery partner are no longer working together or at all individually in the expected training start year of an ECT, we wouldn’t show them as an option for schools to select. 

When this happens and a school can no longer select their previously used choices for the new academic year, we’ll simply ask them the questions for these programme details again, as outlined below.

You can read more about why we chose to use this approach [in the design history entry here](https://teacher-cpd.design-history.education.gov.uk/ecf-v2/saving-default-choices/).


### Giving an ECT’s appropriate body when the school isn’t reusing previous programme details

If a school hasn’t registered an ECT before, or they’ve chosen not to reuse previous programme details, we ask what appropriate body they are working with. These are organisations that take on the role to quality assure the induction of ECTs, and decide if they pass or fail their induction.

Users from state-funded schools which appropriate body will be supporting the ECT’s induction. Only teaching school hubs now work as appropriate bodies for state-funded schools, but historically local authorities could also take on this role. A school’s choice of appropriate body is typically related to their geographical location, and [they are provided with a list to choose from here](https://www.gov.uk/government/publications/statutory-teacher-induction-appropriate-bodies/find-an-appropriate-body).

However, if the school is an [independent school that is section 41 funded](https://www.gov.uk/government/publications/independent-special-schools-and-colleges), the school user will also get the option to select the ‘Independent Schools Teacher Induction Panel (ISTIP)’. 

### Giving an ECT’s training programme

From 2025, all ECTs will either be undertaking provider-led or school-led training.

Schools have to tell us when they register any ECT if they are doing provider-led or school-led training.

This was simplified from the previous programme choices of:

* core induction programme
* full induction programme
* do it yourself 

Core induction programme and do it yourself have been merged together, into school-led.

We decided we did not need to ask schools for a school-led ECT’s learning materials because:

* it might confuse schools not using learning materials
* it would be adding more complexity for when schools register ECTs
* it would be something else to build, costing time and money but with limited value

If a school answers that the ECT is school-led, they’re taken to the check your answers page. 

If a school answers that the ECT is provider-led, they’ll be asked to give the lead provider for that ECT.

### Giving an ECT’s lead provider

In Register early career teachers, we ask for every provider-led ECT that is registered to be given a lead provider the school thinks will be responsible for setting up their training.

We added this because:

* ECTs sometimes get lost because a school doesn’t realise they have to contact a lead provider, and their training is delayed
* we want to reduce the workload and burden on schools to have to reach out separately to lead providers
* we want to reassure schools we’re passing on the information they submit to us to lead providers
* it’s how some schools already assume the service works, and they often get confused which generates support tickets
* it will help lead providers efficiently set up training for the right ECTs

The school will have to choose from a list of lead providers that are able to work with the ECT in their expected training start year.

You can read more about why we chose to ask schools for the lead provider they want to train their ECT [in this design history here](https://teacher-cpd.design-history.education.gov.uk/ecf-v2/asking-for-lead-provider-and-delivery-partner/).

### Checking answers for the registration of an ECT

When the school has submitted all the initial information for an ECT, they can check their answers.

Some of these fields are dependent on other fields.

For example, the TRN assures us this person is definitely a teacher that should be undergoing training. As described above, when provided with a date of birth or national insurance number, it makes sure the school knows this person and that it’s valid to register them for training. It also provides us back with a name that can be corrected.

So, if a school user changes the TRN, it would mean the value it’s changed to might not validly be an ECT that should be registered for training. It could also change it to a different person with a different name. Therefore, we don’t allow changes to the TRN. If they want to change the TRN, they’d have to start the whole registration process again.

The school start date provided might impact what lead provider information a school user selects.

If a school has registered an ECT using previously used programme details, if they decide to change the appropriate body, lead provider, delivery partner or programme type, we’d also just take them back to the question if they want to use previously used programme details again. This simplifies the build and also makes sure they don’t pick any options that might not be feasible.

Once a school confirms the details, it saves the details for that ECT. The ECT record is created, with a status of ‘mentor required’. It creates an ECT record that can be viewed on the ‘ECTs’ page. However, registration is still not finished!

<a id="assigning_a_mentor"></a>

## Assigning a mentor to an ECT

### Assigning a mentor immediately after giving ECT details

Registration is only finished when an ECT is also given a mentor.

All ECTs need mentors, it’s part of the support they should receive at every school. ECTs can start training without having a mentor assigned on the Register ECTs service, and lead providers will get funded for the ECT’s training. However, mentors still need to be assigned to ECTs so they can:
* be eligible for funded provider-led mentor training
* have their details passed on to lead providers for training correctly
* have access to any learning materials for provider-led ECTs to assist them in their mentoring

Schools can choose to assign a mentor for that ECT immediately after saving the details for the ECT, or they can come back later and do this through the homepage. You can read more about why we chose to do this [in this design history here](https://teacher-cpd.design-history.education.gov.uk/ecf-v2/assigning-mentors/).

If they do it immediately, they’re taken to the journey to assign a mentor.

More about the process for assigning a mentor is given in the sections below, but we still don’t see ECTs as fully registered until they have a mentor.

### Assigning a mentor through the ECTs page

Mentors can also be assigned later, if the school doesn’t have the information or time to do it immediately after registering an ECT.

Currently, a school user would only be able to do this by going to the ‘ECTs’ page.

There would be a prompt next to every ECT that has a saved record to assign a mentor, if they don’t already have one.

If the school user selects to assign the ECT a mentor, they’re taken into the journey to assign a mentor.

### Deciding if the mentor is new or a previously registered mentor

Regardless of where the journey to assign a mentor starts, schools are taken to a question where they are asked if they’re assigning a mentor they’ve already registered, or registering a new mentor.

This will show all existing mentors that are still actively at the school - they have an open `mentor_at_school_period`.

If the school selects a previously registered mentor, they will successfully end the journey to assign a mentor, and also finish registering their ECT. This will change the ECT’s status from ‘mentor required’ to ‘registered’. 

If the school registers a new mentor, they’re taken to the questions outlined below.

We would not allow here or later when they find a mentor's record for an ECT to be assigned as their own mentor.

### Finding a mentor’s record in the Teaching Record System

When a school registers a mentor, we need to find the mentor’s TRS record so that we can check they are a real person that the school knows.

To find a mentor’s teacher record, we need to check the Teaching Record System (TRS) API. The mentor needs a TRN, but does not actually need to be a qualified teacher or even working towards qualified teaching status (QTS).

To do this, we ask for the mentor’s TRN and date of birth.

We should always ask for two fields of personal information before registering a mentor’s record. This is because we need to make sure the person registering the mentor actually knows that person. If we just ask for TRN, they could be entering a random number.

If we can’t find a matching TRN that exists, we tell the user the mentor’s teacher record cannot be found.

If we can’t find the mentor’s record in the Teaching Record System API, but the TRN does exist, we ask for that mentor’s national insurance number instead. We do this because potentially the date of birth stored on the record in the TRS is incorrect, or the one the school holds might be. It makes it more likely for the user to find mentor’s ECT’s teacher record and confirm they know them.

If we still cannot confirm the user knows both the TRN and either national insurance number or date of birth, we tell them the record cannot be found.

Neither date of birth or national insurance number should be stored longer-term. It is just used for the initial finding and checking of a mentor’s record in the TRS. You can read more [about our reasoning for this here](https://teacher-cpd.design-history.education.gov.uk/ecf-v2/no-longer-storing-date-of-birth/).

If the mentor does not have teacher reference number, we take school users to a page that informs they of how to either [Find a lost TRN](https://find-a-lost-trn.education.gov.uk/start) or [request a new TRN for the mentor](https://www.gov.uk/guidance/teacher-reference-number-trn#if-youre-a-mentor-for-a-trainee-or-early-career-teacher).

### Confirming or correcting a mentor’s name

Once we’ve decided the mentor can be added to the service, we play back the name from the TRA’s Teaching Record System to the user. This is so we can show them it’s linked to their teacher record and that they must be intending to register that person.

We give users the option to either:

* confirm the name is correct and continue
* correct the name and continue

We did this because:

* we know the name held in the TRS is often out of date
* we want lead providers to have correct contact details for mentors
* we don’t want to block schools from registering someone because the name of the mentor may have been updated

If the name is corrected, we will continue to show the corrected name in the service from this point. We will continue to store the name from the TRS, so we can monitor if this feature is being used correctly, and it’s not being overwritten with names that are completely different.

You can read more about why we chose to change how a mentor’s name is gathered [in the design history entry here](https://teacher-cpd.design-history.education.gov.uk/ecf-v2/correcting-names/).

### Registering a mentor who has been registered before at another school

We still need to define what happens here.

### Giving a mentor’s email address

The school user is asked for that mentor’s email address.

We check the email address given and make sure it doesn’t exist for an ongoing ECT or mentor record with a different TRN. This would mean any emails that are attached to an open `ect_at_school_period` or open '`mentor_at_school_period`. This is because we shouldn’t have email addresses that are the same for entirely different people, when both are are still undergoing training.

This avoids a scenario where two different people are given the same email address. If their lead provider was the same, the lead provider would be unable to set them up with unique accounts for their learning platform.

In addition, it prevents us sending privacy notes or other communication intended for the other person.

We also make sure the email follows a correct format.

### Checking if a mentor can receive mentor training

If a mentor is being assigned to a provider-led ECT for the first-time, we’ll check if that mentor can receive funded provider-led mentor training.

In order to receive funded provider-led mentor training, the mentor must:

* not have taken part in early-rollout mentor training, which was done in the beginning when the ECF was launched
* not have completed provider-led mentor training historically
* not have started provider-led mentor training and taken too long to finish, as defined by policy and submitted to the digital service annually

If the mentor is being assigned to a provider-led ECT and can receive provider-led mentor training, we’ll inform the school of this.

We’ll tell the school we’ll pass on the mentor details to the same lead provider they used when registering an ECT.

We still need to define what happens when a mentor is being assigned to a school-led ECT for the first time. They might still legitimately be able to undertake provider-led training as a mentor, and we know some mentors do do this!

We’re also working on a way for a school to tell us if the lead provider for a mentor is different.

### Checking answers for the registration of a new mentor

We play back all the details submitted for that mentor and remind the school user of the ECT to whom the mentor will be assigned.

Once the school user confirms these details, they have finished:

* registering a new mentor
* assigning a mentor to an ECT
* registering that ECT

The status of the ECT changes from ‘mentor required’ to ‘registered’. A mentor record is also created on our ‘mentors’ page.

