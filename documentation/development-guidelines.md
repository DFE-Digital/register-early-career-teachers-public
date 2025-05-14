---
title: Development guidelines
---

## If there's a native way to do something in Rails, use it

Don't introduce new dependencies without good reason, they need to be kept up to date and replaced if the support for the libary ends.

Be wary of any libraries that change the way Rails works as it makes learning how the application works more difficult for new joiners.

## Be explicit, it makes things easier to follow

Ruby is a beautiful, concise, expressive language --- but it can be hard to understand, especially for junior developers.

#### Call methods after what they do, don't call them `#call`.

##### This

```ruby
a = Teachers::Name.new(teacher)
puts a.full_name
puts a.full_name_in_trs
```


##### Not this

```ruby
a = Teachers::FullName.new(teacher)
b = Teachers::FullNameInTRS.new(teacher)

puts a.call
puts b.call
```

Similarly, to make it clear, we explictly reference FactoryBot when we call it, i.e., `FactoryBot.create(:teacher)` over `create(:teacher)`

## Keep business logic in the service layer

Businss logic is the most complex part of the codebase. Spreading it around makes it hard to find, change and test.

### Pass in the required data

TODO

### Organise by subject

Classes should be organised into namespaces by subject, not by audience.

#### This

```
services
└── teachers
   ├── create.rb
   ├── delete.rb
   ├── induction
   │  ├── fail.rb
   │  └── pass.rb
   ├── search.rb
   └── update.rb
```

#### Not this

```
services
├── admin
│  ├── create_teacher.rb
│  └── delete_teacher.rb
├── api
│  └── create_teacher.rb
├── appropriate_bodies
│  ├── create_teacher.rb
│  ├── pass_induction.rb
│  └── fail_induction.rb
└── schools
   ├── create_teacher.rb
   └── update_teacher.rb
```

We should aim to make classes generic enough to be reused. Ideally there should be one obvious way to do something.
