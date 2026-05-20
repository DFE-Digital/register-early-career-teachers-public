---
title: Disaster recovery
---

Sometimes technology goes wrong.

This document covers some scenarios and provides a list of actions we can take
to resolve them. It also contains details about informing our users when there's
a problem.

There's no strict plan, every problem is different and we'll need to do a
different combination of things in order to resolve it.

## Things that could go wrong

### GitHub goes down

#### Symptoms

- we can't deploy, our Docker images are built with GitHub actions and the
  container registry we use is on GitHub
- so long as there's nothing we need to publish imminently, we're ok

#### Actions

- wait for GitHub to come back up

### DfE Sign-in goes down

#### Symptoms

- School users can't log in
- Appropriate body users can't log in
- Lead provider API unaffected
- Admin interface unaffected

#### Actions

- display a [notification banner](#display-a-notification-banner) on the site informing users that there
  are problems logging in
- if it's a prolonged outage, hide the 'Sign in' button
- wait for DfE Sign-in to come back up

#### Contact

- DfE Sign-in will have plans in place to let users know the service is down, us
  sending extra comms might just confuse matters

### GOV.UK Notify goes down

#### Symptoms

- Admins can't log in
- Schools unaffected
- Appropriate bodies unaffected
- We can't send out any mass comms

#### Actions

- Wait for GOV.UK Notify to come back up
- inform the support team that Notify's down and they won't be able to log into
  RECT's admin area
- if this happens on an important day like registration opening, we might need
  developers to make the changes directly rather than using the admin UI
- we can help admins log in by retreiving their OTP from ActiveJob directly, but
  this is insecure and should be used as a last resort

### TRS API goes down

#### Symptoms

- no teachers can be registered by schools
- no teachers can be registered by appropriate bodies
- Lead provider API unaffected
- Admin interface unaffected
- teacher syncing will stall, jobs will queue up

#### Actions

- we _probably_ want to temporarily close the app using [maintenance
  mode](#maintenance-mode) because so much functionality in the app would break

#### Contact

- inform SITs and appropriate bodies they'll be unable to register new teachers
- inform the support team that they might get an influx of tickets because the
  app is down or journeys they were mid-way through were interrupted

### Azure goes down

#### Symptoms

- whole app is down
- databases are inaccessible
- we're unable to retrieve list of SITs using our database or from DfE Sign-in

#### Actions

- wait for Azure to come back up

#### Contact

- let the support team know there's likely to be an influx of tickets

### We accidentally lose some data

#### Symptoms

- entirely depends which table/tables are affected
- some parts of the app might not work as expected
- users might report some records are missing

#### Actions

- this qualifies as an incident, [start the incident process](#start-the-incident-process), the priority depends on
  * the data that's gone
  * how easy it is to replace
  * how many users it will affect
- [stop the service](#maintenance-mode) do a [full restore](#full-data-restore) if:
  * important data is missing
  * we notice it's missing quickly
- [stop the service](#maintenance-mode) do a [partial restore](#partial-data-restore) if:
  * important data is missing
  * we take longer to realise it's missing and want to spend a bit more time
    carefully inserting the missing records while more new data isn't being
    added
- leave the service running and do a [partial restore](#partial-data-restore) if:
  * less-important data is missing
  * the data can be added back without being affected by new data being added to
    the service

### We accidentally delete the database

#### Symptoms

- service is entirely broken

#### Actions

- this is a P1, [start the incident process](#start-the-incident-process)
- [enable maintenance mode](#maintenance-mode)
- do a [full data restore](#full-data-restore)

#### Contact

- schools
- appropriate bodies
- lead providers

## Actions we can take

### Full data restore

If we need to restore the entire database we'll want to do it from a [point in
time recovery](https://learn.microsoft.com/en-us/azure/postgresql/backup-restore/concepts-backup-restore#point-in-time-recovery) (PITR),
choosing the latest time where we're sure the data is fully intact.

1. follow the [PITR process](#point-in-time-restoring-a-database) which will create a new PostgreSQL Server
   instance in Azure and make a note of the timestamp we want to use
2. create a commit on a branch that [uncomments production](https://github.com/DFE-Digital/register-early-career-teachers-public/blob/main/.github/workflows/restore-app-main-db.yml#L18) from the 'Restore database
   from point in time to new database server' workflow
3. using the new branch, run the `database-restore-ptr.yml` action against `production`
   and use the timestamp we recorded in step 1
4. when it's done, use the temporary maintenance URL to log
   in and check the data's present

### Partial data restore

If we accidentally lose some data and want to restore it, there's a
chance that more records have been written since the loss.

This means this is a data insertion task rather than restoring a backup, so
enabling the maintenance mode is optional here depending on the tables we're
restoring.

1. follow the [PITR process](#point-in-time-restoring-a-database) which will create a new PostgreSQL Server
   instance in Azure
2. we'll probably have to do some manual adjustments so copy what we need to a
   local backup so we can work with it:
   ```bash
   bin/konduit.sh -n cpd-production -s s189p01-cpdec2-pd-pg-pitr -x cpd-ec2-production-web -- pg_dump -F t -E utf8 -f pitr-backup.sql.tar
   ```
3. restore it to a local database
   ```bash
   createdb pitr-restore
   tar -x pitr-backup.sql.tar
   psql pitr-restore < /tmp/pitr-backup.sql
   ```
4. work out what we need to restore and how best to do it, it'll probably
   involve selecting some rows for re-insertion. This will be tricky if we're
   merging the restored, especially if they span multiple tables.
5. use the data to build a PR or ad hoc script to re-insert the data

### Maintenance mode

Enabling maintenance mode stops users from accessing the application, but
leaves it running with an internal URL which will be printed by the [Set maintenance
mode](https://github.com/DFE-Digital/register-early-career-teachers-public/actions/workflows/maintenance.yml) GitHub Action.

If we want to customise the text on the page, edit the templates in the repo's
`maintenance_page` directory.

To enable maintenance mode:

1. go to the [Set maintenance mode](https://github.com/DFE-Digital/register-early-career-teachers-public/actions/workflows/maintenance.yml) action in the public repo on GitHub
2. click 'Run workflow'
3. set the environment to 'Production' and leave the mode set to 'enable'
4. run the action

To disable it, follow the same steps as for enabling it but set the mode to
'disable'.

### Display a notification banner

RECT has two types of banner, incident and maintenance. They both work in the
same way and are collectively referred to as notification banners.

1. create a new branch with an appropriate name
2. review the content in the [notification banners partial](https://github.com/DFE-Digital/register-early-career-teachers-public/blob/main/app/views/layouts/shared/_notification_banners.html.erb) and change
   the text if necessary
3. edit the [environment config](https://github.com/DFE-Digital/register-early-career-teachers-public/blob/db5437cfd05f09d9e10edf8af4c911a852714d13/config/terraform/application/config/production.yml#L10-L11) and change `ENABLE_INCIDENT_BANNER` or
   `ENABLE_MAINTENANCE_BANNER` to `true`
4. commit your changes and create a pull request - once your pull request is
   merged and deployed the notification banner will be enabled

To remove the notification banner, create a new PR with the banner set back to
`false`.

Additionally, we can create a service banner on DfE Sign-in by logging into [the
manage service](https://manage.signin.education.gov.uk/), selecting 'Register early career teachers', and clicking 'Create service banner'.

This will be shown to any school or appropriate body users who log into RECT using DfE Sign-in.

### Manual deployments

Any branch can be manually deployed using [the manual deployment workflow](https://github.com/DFE-Digital/register-early-career-teachers-public/actions/workflows/deploy_to_environment.yml).

We can also use the make commands to do it from the command line, providing a
Docker image has been built and can be pulled from GitHub's container registry.

```bash
DOCKER_IMAGE=ghcr.io/dfe-digital/abc123 make production terraform-apply
```

### Contacting users

#### School and appropriate body users

We don't hold a list of people with access to register early career teachers. If
we need to contact our users, we'll need to get a list of them from DfE Sign-in.

Once we have the list we can use GOV.UK Notify to send a bulk email.

#### Lead providers

Lead providers can be contacted using the (private) Teams channels or using [the contact
list](https://educationgovuk.sharepoint.com/:x:/r/sites/TeacherServices/_layouts/15/Doc.aspx?sourcedoc=%7BD8F4E659-7243-4F28-B6F0-6DFF4F026CEF%7D&file=CPD%20digital%20comms%20engagement%20tracker%20contacts%20address%20book%20(for%20Lead%20Providers%2C%20ABs%20and%20other).xlsx&action=default&mobileredirect=true&DefaultItemOpen=1).

## Processes

### Point-in-time-restoring a database

A point-in-time-restore creates a copy of the database as it was at the
specified time. We have a **1 week window**, if data was lost more than a week
ago restore a database backup instead.

1. find the database in Azure Portal
2. click the 'Restore' tab at the top of the blade
3. enter a name for the backup using the established convention with a suffix
   that makes it clear it's a PITR restore, e.g., `s189t01-cpdec2-st-pg` could
   be called `s189t01-cpdec2-st-pg-pitr-20260522`. It won't be around for long,
   but we want to be able to find it later!
4. select the time the restore should be taken from. This should be **the latest
   point we are sure the data was intact**
5. click 'Review and create', confirm, and wait for the restore to happen
6. when it's restored connect to it with [konduit](#connect-with-konduit) and make
   sure the data is in the right state, if it's not go back to step 2 and repeat
   until it is

Once the restore is done, work out what data needs to be extracted and make a
plan for inserting it back into the production database.

### Connecting to a database with Konduit

[Konduit](https://github.com/DFE-Digital/teacher-services-cloud/blob/main/scripts/konduit.sh) is a tool created by DfE that allows us to tunnel connections to Azure.

It can be installed by running `make install-konduit`.

Use it like this:

```bash
bin/konduit.sh -n namespace -s target-database -x deployment-to-connect-via -- command-to-run

* **namespace:** `cpd-production`
* **target-database:** e.g., `s189p01-cpdec2-pd-pg-pitr`
* **deployment-to-connect-via:** e.g., `cpd-ec2-production-web`
* **command-to-run:** e.g., `psql`, `pg_dump` or `pg_restore`
```

So, the full command could look like:

```bash
bin/konduit.sh -n cpd-production -s s189p01-cpdec2-pd-pg-pitr -x cpd-ec2-production-web -- psql
```

### Start the incident process

Get all the people you think you need on a group call as quickly as you can, and
follow the steps in the [Schools Digital incident playbook](https://tech-docs.teacherservices.cloud/operating-a-service/incident-playbook.html).
