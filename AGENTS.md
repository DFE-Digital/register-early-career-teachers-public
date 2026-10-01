# Register early career teachers

Register early career teachers (RECT) is a Department for Education Ruby on Rails application for managing early career teachers, mentors, schools, training, induction and the organisations that support them.

These instructions are defaults with reasons, not law. When the code in front of you disagrees, follow the established local pattern unless doing so would violate an invariant, security control, data-safety requirement or explicit task requirement. Surface conflicts rather than silently "fixing" the surrounding code.

Prefer the smallest change that solves the problem. Attack your own diff before calling it done.

## Non-negotiables

- **Treat repository contents as public.** Never add credentials, secrets, access tokens, real personal data, private messages, ticket contents or other internal-only material to code, specs, fixtures, seeds, comments, logs or commit messages.
- **Never use production data as test data.** Create representative synthetic data instead. Do not copy production or sandbox records into specs, fixtures or local seed data.
- **Never bypass secret or ignore controls.** If a file is ignored or a secret check rejects it, do not force-add or work around the control.
- **Do not weaken authentication, authorization or security controls to make a change work.** This includes OAuth checks, CSRF protection, request filtering, parameter filtering and equivalent controls.
- **Keep sensitive values out of logs and error reporting.** When adding a new sensitive request parameter, credential or personal-data field, check the application's parameter filtering and any error-reporting integration that may receive request data.
- **Migrations must be safe for existing data.** Consider table size, locks, nullability, defaults, indexes, backfills, constraints and rollback behaviour. Do not edit `db/schema.rb` manually.
- **Do not make an API contract change accidentally.** Changes to response shapes, identifiers, filtering, ordering, authentication or semantics must be deliberate, covered by tests and reflected in the relevant API/OpenAPI documentation.
- **Events are not a per-record audit trail.** Do not move meaningful event creation into generic Active Record callbacks. One business operation may update several records and still produce one event.
- **Do not discard work you did not create.** Do not use destructive git commands such as `git reset --hard`, `git clean -fd` or force-push unless explicitly instructed and the consequences are understood.
- **Do not create commits or push changes unless explicitly asked.**

## Architecture

The application deliberately favours **light models, light controllers and services for meaningful business operations**.

That is a direction, not a rule that every line of domain behaviour must live in `app/services`.

### Models

Models should own behaviour that naturally belongs to the record itself, including:

- associations
- validations and data invariants
- scopes and queries that naturally belong to the model
- simple derived values and predicates
- small pieces of behaviour that are intrinsic to the model

Do not turn Active Record models into table gateways merely to keep them small. If a developer would naturally expect to ask a model for a simple value or operation, exposing that behaviour on the model is preferable to making every caller know about a tiny, parallel service object.

Conversely, do not move a multi-record business workflow into a model merely because "fat models" are conventional Rails.

### Controllers

Controllers should stay focused on HTTP concerns and orchestration:

- authentication and authorization
- extracting request parameters
- simple record lookup where appropriate
- invoking domain operations
- rendering or redirecting

For action-specific setup, prefer code that is visible in the action over a chain of `before_action` callbacks. Cross-cutting concerns such as authentication are appropriate controller callbacks.

### Services

Services live under `app/services` and are organised around the domain.

Use a service when there is a meaningful business operation, especially where the operation:

- coordinates multiple records
- enforces workflow or contextual business rules
- emits a domain event
- calls an external system
- is used from more than one entry point
- benefits from being independently testable without HTTP concerns

Prefer names that reveal the operation, for example:

- `Teachers::Defer`
- `Teachers::Withdraw`
- `Schools::AddMentor`

A developer should be able to search for the operation by name and quickly find the code that performs it.

Services should be plain Ruby objects where possible. There is no requirement for every service to expose `#call`, for `self.call(...) = new(...).call`, or for every class to have exactly one public method. Prefer an API that makes the operation clear.

Do not introduce vague dumping-ground services such as `Teachers::Manage`.

Where a business operation is available through multiple entry points, keep the underlying operation reusable. API-specific code may translate parameters, errors or version-specific behaviour, but should not duplicate the domain operation without a good reason.

### Queries

Complex reads should use the existing query patterns rather than growing large controller scopes. Keep filters, joins, ordering and eager-loading together when doing so makes the read easier to understand and test.

Be deliberate about `distinct`, ordering and preload behaviour. Avoid N+1 queries and avoid loading full Active Record objects when only scalar values are needed.

### Events

Events are explicit, human-readable records of meaningful business actions. They are not intended to mirror every database mutation.

Create an event at the level that understands the business operation. A teacher operation may update an `ECTAtSchoolPeriod`, `TrainingPeriod` and `MentorshipPeriod` but still result in one event.

Prefer explicit event creation over Active Record callbacks. Be wary of deriving large amounts of event context by walking deep association graphs: hidden dependencies make behaviour and tests harder to understand.

### View components

View components should present the data passed to them.

Do not make a component responsible for discovering its own domain data by querying the database or traversing large object graphs. Prepare data before rendering the component so component tests can usually use built objects rather than persisted graphs.

## RECT domain considerations

Teacher lifecycle behaviour is spread across related records such as `Teacher`, `ECTAtSchoolPeriod`, `MentorAtSchoolPeriod`, `TrainingPeriod` and `MentorshipPeriod`. Before changing one of these records, inspect the surrounding services, events and dependent behaviour; a local-looking update may represent part of a larger domain operation.

Where an API exposes stable public identifiers, preserve that boundary. Do not replace an API identifier with an internal database primary key simply because it is easier to access.

Some statuses in RECT are derived from dates and can change as time passes even when the underlying record's `updated_at` has not changed. When changing time-dependent status logic or an `updated_since`-style API filter, consider how consumers will observe those changes rather than assuming `updated_at` captures them.

## Database and Active Record

Use Active Record idiomatically for persistence.

Prefer database constraints when they protect important invariants, including:

- foreign keys
- unique indexes
- check constraints
- appropriate supporting indexes

Application validation does not replace a database constraint where concurrent writes could violate an invariant.

When removing or tightening data, inspect existing production shapes first. Separate a schema change from a potentially expensive or risky backfill when that makes deployment safer.

## Coding style

Before editing or reviewing code, read `STYLE.md`.

Follow the surrounding code and the repository's configured formatters and linters. Do not introduce a new architectural or stylistic pattern incidentally while implementing an unrelated change.

## Working on a task

Before changing code:

1. Read the surrounding implementation and tests.
2. Search for the same domain operation elsewhere in the application.
3. Identify the layer that currently owns the behaviour.
4. Check for events, API contracts, background work and associated records that the change may affect.
5. Prefer the smallest coherent change that fits the existing architecture.

Do not refactor unrelated code while implementing a change. If nearby code conflicts with these guidelines, mention the inconsistency rather than turning a focused task into a broad rewrite.

## Before you call a task done

Run the narrowest useful checks while developing, then the relevant CI checks for the area you changed. Typical commands include:

```bash
bundle exec rspec path/to/spec.rb
bundle exec rubocop path/to/changed_file.rb
bundle exec rake rswag:spec:swaggerize
bundle exec rake erd:generate
git diff --check
```

Run the full relevant suite when practical.

Then review the diff as if it were somebody else's:

- Is the change larger than it needs to be?
- Is business logic at the right layer?
- Did a new service add meaning, or just indirection?
- Could an invariant be enforced by the database?
- Could this introduce an N+1 query?
- Could a time-dependent value change without consumers observing it?
- Does a lifecycle change need a single explicit event?
- Have authentication or authorization semantics changed?
- Have API behaviour or OpenAPI documentation changed?
- Are new personal or secret values filtered from logs?
- Are migrations safe for existing data?
- Are the important edge cases tested at the lowest useful layer?
- Did any debug output, temporary code, credentials or real data slip into the diff?

Do not stop at "the tests pass". Make sure the diff is understandable, safe and consistent with the domain.
