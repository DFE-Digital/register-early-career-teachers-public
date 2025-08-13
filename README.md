# Early Career Framework Version 2

ECF is a framework of standards to help early career teachers succeed at the start of their careers.

## Workflows

[![App deployment](https://github.com/DFE-Digital/register-early-career-teachers-public/actions/workflows/deploy.yml/badge.svg)](https://github.com/DFE-Digital/register-early-career-teachers/actions/workflows/deploy.yml)
[![Service manual deployment](https://github.com/DFE-Digital/register-early-career-teachers-public/actions/workflows/publish-documentation.yml/badge.svg)](https://github.com/DFE-Digital/register-early-career-teachers/actions/workflows/publish-documentation.yml)

## Documentation

* [ECF service manual](https://register-ects-service-manual.education.gov.uk/)
* [Design history](https://teacher-cpd.design-history.education.gov.uk/ecf-v2/)
* [Glossary](./documentation/glossary.md)

### Technical stuff

* [Data schema](https://github.com/DFE-Digital/register-early-career-teachers/wiki/Data-schema)
* [Setup guide](./documentation/setup.md)
* [State machines](./documentation/state-machines.md)
* [Parity check](./documentation/parity-check.md)
* [CSV processing](./documentation/csv-processing.md)
* [Metadata](./documentation/metadata.md)

## Repository setup

Register early career teachers has two repositories, [an internal](https://github.com/DFE-Digital/register-ects-project-board) one and [a public one](https://github.com/DFE-Digital/register-early-career-teachers-public).

We write tickets and organise our sprints on the internal repository. The public one is where we write and update code. This helps minimise the risk of accidentally posting sensitive information in a ticket, but still allows for our code to be public and transparent.

We still aim to work as openly as possible and will respond to any issues or pull requests raised against the public repository.


## Entity Relationship Diagram

This diagram is generated from the application's models and shows their relationships.

👉🏽 [View Mermaid ERD](documentation/domain-model.md)
