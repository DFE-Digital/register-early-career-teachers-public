# Style

We aim for code that is easy to find, easy to follow and unsurprising to a developer who is new to RECT.

The codebase has deliberately favoured a seam of business logic between controllers and models. The goal is not to minimise the number of lines in models at all costs; it is to make meaningful operations obvious, independently testable and reusable without hiding behaviour behind callbacks or framework magic.

These are defaults with reasons. Existing code may reflect older approaches. When making a focused change, follow the local pattern unless changing it is part of the task.

## Start with the code that already exists

Before introducing a new pattern, find similar code in the same area.

Prefer:

- explicit code over hidden behaviour
- domain-specific names over generic abstractions
- established application patterns over a new framework or pattern
- straightforward duplication over premature abstraction
- small coherent diffs over incidental refactors

A style guide is not a reason to rewrite neighbouring code.

## Models

Keep models light, but not anaemic.

Models are a good home for behaviour that is intrinsic to the record and reads naturally from the record's point of view: associations, validations, scopes, predicates and simple derived values.

For example, callers should be able to ask a teacher for a naturally modelled value without knowing where its implementation happens:

```ruby
teacher.full_name
```

If the existing implementation is already usefully isolated, the model can provide the natural API and delegate internally:

```ruby
class Teacher < ApplicationRecord
  def full_name = Teachers::Name.new(self).full_name
end
```

That is preferable to making every caller know that a value belonging to a teacher lives behind `Teachers::Name`.

Do not, however, put a workflow involving several records, side effects and events onto an Active Record model merely to avoid a service.

### Validations

Put invariants close to the data they protect when the rule is genuinely shared by all entry points.

Keep transport or version-specific concerns at the boundary. An API may need different parameter handling, error presentation or compatibility behaviour, but that does not automatically make the underlying domain rule API or version specific.

When a rule is contextual rather than universal, make that context explicit rather than hiding it in an unconditional callback.

## Controllers

Controllers should be lighter than models and services.

Keep authentication, authorization, parameter handling, simple lookup, orchestration and response handling in the controller. Move meaningful business operations out.

A simple lookup is fine:

```ruby
def show
  @teacher = Teacher.find(params[:id])
end
```

Avoid making an action look empty because all of its work happens in action-specific callbacks.

```ruby
# Avoid
before_action :set_mentor, only: :show
before_action :set_teacher, only: :show
before_action :set_ects, only: :show

def show
end
```

Prefer making action-specific data dependencies visible:

```ruby
def show
  @mentor = ...
  @teacher = ...
  @ects = ...
end
```

Use `before_action` for genuine cross-cutting behaviour, such as authentication, or small setup that is consistently shared across several actions.

## Services

Use services for **meaningful domain operations**, not as a mandatory wrapper around Active Record.

Organise them under the domain so their names answer "where does this happen?":

```text
Teachers::Defer
Teachers::Withdraw
Schools::AddMentor
```

A service name should describe the operation. Avoid generic buckets such as `Teachers::Manage`, `Teachers::Processor` or `Teachers::Service`.

### Service APIs

Services are plain Ruby objects.

Use `#call` when the service represents a single operation and the class name already describes that operation:

```ruby
API::OAuth::Authorizations::Create.new(...).call
```

If a service exposes multiple related behaviours, prefer descriptive method names:

```ruby
Teachers::Name.new(teacher).full_name
Teachers::Name.new(teacher).full_name_in_trs
```

Do not split cohesive behaviour into extra classes merely to enforce one public method per service, and do not use `#call` when a descriptive method name makes the API clearer.

### Keep dependencies explicit

Prefer passing the data a service genuinely needs over making it discover a large hidden object graph.

Avoid reducing arguments merely by teaching a service to traverse several associations internally. That creates hidden preconditions and often forces tests to persist an entire graph just to exercise a small piece of behaviour.

Balance this against noisy parameter lists: pass cohesive domain objects where their immediate associations are genuinely part of the concept, but do not hide deep dependencies for the sake of a shorter initializer.

## Events

RECT events are human-readable records of business actions, not PaperTrail-like records of every model mutation.

Create them explicitly from the layer that understands the complete operation.

For example, registering or changing a teacher may mutate several period records. Do not emit one event from each model callback. Emit the event that describes what the user or system actually did.

This is one of the cases where explicit orchestration is preferable to Rails callback magic.

## Callbacks

Avoid callbacks for business processes unless the behaviour is an invariant of the record itself and cannot sensibly be forgotten by a caller.

Callbacks are particularly poor fits when:

- several records are changed as one business operation
- an event should be emitted once for the whole operation
- the callback needs request or current-user context
- the callback triggers more callbacks and obscures execution order

A developer should be able to find the entry point for an operation and follow the code down to the database without reconstructing a hidden callback chain.

## Queries and Active Record

Use Active Record directly for straightforward reads.

Extract a query object or existing query abstraction when a read contains enough filtering, joins, ordering, deduplication or eager-loading that keeping it together makes the behaviour clearer.

Be explicit about:

- default ordering
- `distinct`
- joins that change result cardinality
- eager loading
- whether a filter applies to current, historical or future records

Avoid N+1 queries.

Use `pick`, `pluck`, `exists?` and similar APIs when you only need scalar data; do not load full records unnecessarily.

## View components

View components present data; they should not discover it.

Pass the component the values or objects it needs. Do not hand it one record and make the component query the database or walk a large association graph to construct its own view model.

Keeping components presentation-focused makes their tests faster and allows `build`/plain objects rather than requiring persisted FactoryBot graphs.

## Testing

Test behaviour at the lowest useful layer.

The goal is not to repeat the same edge cases through feature, request, service and model specs. Each layer should prove something different.

### Feature/system specs

Keep a small number of high-value end-to-end examples, primarily happy paths.

Use them to prove the application is wired together and a user can complete the important journey. Do not put the full business-rule matrix here.

### Request specs

Request specs should mainly prove HTTP behaviour:

- authentication and authorization
- parameter extraction and translation
- the correct domain operation is invoked with the correct inputs
- status codes, redirects and response shape

Do not make request specs the primary home for intricate business-rule edge cases when those rules live in a service.

### Service specs

Service specs should contain most of the examples for business operations, including edge cases and combinations of domain rules.

Keep them focused on the service's inputs and observable result. Avoid requiring HTTP state when the operation itself does not depend on HTTP.

### Model specs

Model specs should focus on:

- validations
- associations
- scopes
- model-level invariants
- behaviour intrinsic to the model

If a natural model API delegates to an extracted object, prefer testing the observable model behaviour where that gives callers a stable contract.

### Components and views

Test presentation with the least persistence necessary.

Prefer `FactoryBot.build` or plain objects when a test does not need the database. Do not create a complex persisted graph merely because a component quietly reaches into associations; change the component boundary instead.

### Test data

Do not introduce a wholesale testing-style migration as incidental work.

Where stable reference fixtures already exist, they are appropriate for background records that are expected to be present. Where factories are used, avoid unnecessary `create` calls and build only the graph the behaviour actually needs.

## Abstractions

Extract an abstraction when it makes the domain easier to understand, not because two snippets happen to look similar.

Prefer a little duplication to an abstraction with vague names or multiple unrelated responsibilities.

Before creating a base class, concern, generic service or metaprogrammed DSL, ask whether a developer searching for the domain operation will find the code more quickly or less quickly afterwards.

## Naming

Use domain language.

Names such as `Teachers::Defer` communicate an action and make usages easy to search. Names such as `Manager`, `Handler`, `Processor` and `Helper` usually hide what the object is for.

Methods should also describe their behaviour. A meaningful method such as `defer`, `withdraw` or `record_event` is preferable to a generic `call` when it makes the API clearer.

## Comments

Prefer code that explains what it does and comments that explain **why**.

Comments are useful for non-obvious domain constraints, compatibility requirements, migration safety and decisions that would otherwise tempt a future developer to "simplify" something incorrectly.

Do not use comments to narrate straightforward Ruby.

## Consistency

When the codebase contains competing styles, do not choose a third one.

Follow the established pattern in the area you are changing unless the task is specifically to improve that pattern. If the local pattern appears harmful or conflicts with `AGENTS.md`, flag it in the change rather than broadening the scope without discussion.
