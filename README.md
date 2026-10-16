# Early Career Framework Version 2

ECF is a framework of standards to help early career teachers succeed at the start of their careers.


## Workflows

[![App deployment](https://github.com/DFE-Digital/register-early-career-teachers-public/actions/workflows/deploy.yml/badge.svg)](https://github.com/DFE-Digital/register-early-career-teachers/actions/workflows/deploy.yml)
[![Service manual deployment](https://github.com/DFE-Digital/register-early-career-teachers-public/actions/workflows/publish-documentation.yml/badge.svg)](https://github.com/DFE-Digital/register-early-career-teachers-public/actions/workflows/publish-documentation.yml)

## Documentation

* [ECF service manual](https://register-ects-service-manual.education.gov.uk/)
* [Design history](https://teacher-cpd.design-history.education.gov.uk/ecf-v2/)
* [Glossary](./documentation/glossary.md)
* [API validation errors](./documentation/api-validation-errors.md)

### Technical stuff

* [Data schema](https://github.com/DFE-Digital/register-early-career-teachers/wiki/Data-schema)
* [Setup guide](./documentation/setup.md)
* [DfE Sign In](./documentation/dfe-sign-in.md)
* [State machines](./documentation/state-machines.md)
* [CSV processing](./documentation/csv-processing.md)
* [Metadata](./documentation/metadata.md)
* [API tokens](./documentation/api-tokens.md)
* [Environments](./documentation/environments.md)
* [Time travelling middleware](./documentation/time-travelling-middleware.md)
* [Training period logic](./documentation/training_period_logic/)

### Services we rely on

#### UK Government

* [Get Information about Schools](https://www.get-information-schools.service.gov.uk/) - we hold a full list of schools and retrieve updates nightly
* [Teaching record system](https://www.gov.uk/guidance/check-a-teachers-record) - we look up teachers when they're being registered and record induction outcomes, all teacher data is synced every few days
* [DfE Analytics](https://github.com/DFE-Digital/dfe-analytics) - all web and most database data is fed to DfE Analytics, hosted on BigQuery, to power dashboards
* [DfE Sign in](https://services.signin.education.gov.uk/) - used to authenticate school and appropriate body staff who log into the application
* [GOV.UK Notify](https://www.notifications.service.gov.uk/) - all emails, including ones containing one-time passwords, are sent via Notify

#### External

* [GitHub](https://github.com/) - code hosting, issue tracking, project management, deployment
* [Sentry](https://sentry.io) - application monitoring
* [Logit.io](https://logit.io/) - logging, metrics
* [StatusCake](https://www.statuscake.com/) - alerts when there are problems with the web application
* [Zendesk](https://becomingateacher.zendesk.com/hc/en-us) - managing support queries raised by our users

## Repository setup

Register early career teachers has two repositories, [an internal one](https://github.com/DFE-Digital/register-ects-project-board) and [a public one](https://github.com/DFE-Digital/register-early-career-teachers-public).

We write tickets and organise our sprints on the internal repository. The public one is where we write and update code. This helps minimise the risk of accidentally posting sensitive information in a ticket, but still allows for our code to be public and transparent.

We still aim to work as openly as possible and will respond to any issues or pull requests raised against the public repository.


## Entity Relationship Diagram

This diagram is generated from the application's models and shows their relationships.

👉🏽 [View Mermaid ERD](documentation/domain-model.md)

