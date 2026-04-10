---
title: Understanding unfunded mentors
sidebar_position: 12
---
This guidance explains:

- what an unfunded mentor is
- how to identify an unfunded mentor

## What is an unfunded mentor?
Unfunded mentors are mentors who are mentoring ECTs that a lead provider trains, but are not eligible for funded training through that lead provider. This is typically because they have already completed mentor training, or are currently doing so, with a different lead provider.

Lead providers will be funded to give these mentors access to learning materials and platforms so that they can support ECTs they are mentoring.

For example, a lead provider might be training an ECT named Bob. Bob is assigned Laura as a mentor. Laura has already completed training with a different lead provider. As a result, she would appear as an unfunded mentor to the lead provider via the API, because they would not be funded for providing her with mentor training.

Laura's details are shown to the lead provider via the API so they can set her up in their learning platform to support Bob. The lead provider could identify Laura as Bob's mentor by using the 'mentor_id' for Bob in 'GET /participants'.

### What an unfunded mentor isn't
An unfunded mentor is not:

- a mentor who a lead provider is currently training
- a mentor who a lead provider used to train but is no longer training
For example, if a lead provider used to provide mentor training for a mentor named Sarah, and she completed training but was still actively mentoring ECTs, she would:

- no longer be eligible for any more funded training
- still require access to learning platforms or systems to support any ECTs the lead provider was training that she continued to mentor

The lead provider was previously funded for her training, so she would not appear via the 'GET /unfunded-mentors' endpoint. Lead providers could identify Sarah as the mentor for ECTs they were training by using the 'mentor_id' for those ECTs in 'GET /participants'.

## View all unfunded mentors

`GET /api/v3/unfunded-mentors`

For more information on this endpoint, [view the Swagger documentation](/api/docs/v3#/Unfunded%20mentors/get_api_v3_unfunded_mentors)

## View a specific unfunded mentor

`GET /api/v3/unfunded-mentors/{id}`

For more information on this endpoint, [view the Swagger documentation](/api/docs/v3#/Unfunded%20mentors/get_api_v3_unfunded_mentors__id_)
