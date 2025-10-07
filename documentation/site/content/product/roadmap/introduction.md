## Why we're sharing our roadmap publicly 
This document explains what we're working on to improve and rebuild the digital services that facilitate the early career framework (ECF) policy reforms. These digital services are named Register early career teachers.

It sets out what we're working on now, what will come next, and what we might pursue later. 

By sending this out publicly, we hope to:

* give direction to our team
* be transparent about what we're working on and why
* gather more feedback about the work we're aiming to do

All of these items of work are related [to our objectives as a team.](/product/objectives) 

## The services that make up Register early career teachers (ECTs)

Register early career teachers is comprised of:

- Register ECTs, where schools register their ECTs and mentors to receive training and funding
- an API for lead providers, where they can receive and send information about the training of ECTs and mentors to the DfE
- Record inductions, where appropriate bodies can tell us an ECT is serving induction with them, and whether they've passed or failed
- a joint admin and finance console to view information and aid in support queries for all our users

We decided to combine Record inductions and the rest of the services for training because:

- induction data is used by these training services, so being closer together made sense
- historically, there was a separate service for appropriate bodies to check ECT data submitted by schools, whilst now there can be one for them to do this and record inductions
- in the future, we hope to try to deduplicate registration for schools, so appropriate bodies can just approve of information schools submit relevant to induction

## What we've done

So far, we have:

* built a way for schools to register ECTs and mentors to save school's time and improve data accuracy
* set up DfE Sign in for appropriate bodies and schools, so we can improve how all users access the service
* improved how mentors are assigned to ECTs, so we can reduce having to chase schools to tell us mentor information
* built a service for appropriate bodies to record data about inductions individually, so we can start to consolidate services and reduce workload for all users
* released a way for appropriate bodies to record and submit outcomes for inductions in bulk
* set up how we want to migrate data from ECF1 to the new Register early career teachers service
* designed and built how ECTs and mentors are registered when they are moving schools
* built how ECT and mentor records are viewed by schools so school users can understand their status
* designed how schools tell us ECTs and mentors are no longer at a school, so we get more accurate information on if they are still training to share with appropriate bodies and lead providers
* built multiple endpoints on the API, including improvements so we speed up the onboarding of ECTs and mentors to training
* released the draft API specification and started acting on feedback so we can iterate the rest of our API build to meet lead provider needs
* released our API guidance, so we can give information to lead providers as we build the API and they can test it and feedback as it's being developed
* built a lot of the admin tooling we'll require, including admin tooling, in one centralised admin tool for all of our DfE users
* built our 'parity check' for the API, to ensure we migrate data correctly and can inform lead providers of data changes
* improved how schools can make changes to ECT and mentor records, so we can get more accurate information for them
* designed how to gather a singular school induction tutor for schools so we make sure lead providers have the information they need


  
													
# The roadmap


