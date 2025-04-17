# We had a problem with imported data where some records were adjusted so they
# had a length of 1 day instead of 0 (no longer allowed). That adjustment meant
# there's a chance they overlap other periods.
#
# We want to delete those periods that:
#   - start on the same day as another period
#   - are 1 day long
#
# The following query:
#   - finds all teachers that have 2 induction periods starting
#     on the same day
#   - finds induction periods belonging to those
#     teachers
#   - limits those induction periods to ones that are 1 day long
#
# with teachers_with_2_induction_periods_starting_on_the_same_day as (
#       select teacher_id, started_on, count(*)
#       from induction_periods
#       group by teacher_id, started_on
#       having count(*) > 1
# )
# select induction_periods.id
# from induction_periods
# inner join teachers on induction_periods.teacher_id = teachers.id
# where teacher_id in (
#       select teacher_id
#       from teachers_with_2_induction_periods_starting_on_the_same_day
# )
# and (finished_on - started_on) = 1

# rubocop:disable Style/NumericLiterals, Layout/MultilineArrayLineBreaks
induction_periods_to_delete = [
  1032,  1195,  2740,  4300,  5039,  5040,  5983,  10154, 10155, 10519,
  14562, 14637, 14669, 15110, 16456, 17101, 17212, 17440, 17696, 17879,
  20660, 20661, 22474, 22646, 23237, 23285, 23963, 24010, 24227, 24253,
  24410, 24648, 25696, 25718, 25719, 25925, 26534, 27024, 27508, 27513,
  27577, 27578, 28624, 28670, 30473, 32510, 32663, 32724, 34996, 35004,
  36835, 37951, 38285, 42363, 42551, 44587, 46027, 47046, 47350, 47744,
  47838, 47839, 47920, 47941, 50900, 50959, 51081, 51090, 51112, 51401,
  51927, 52791, 55472, 56214, 58048, 58200, 58717, 58766, 58786, 59622,
  59988, 61071, 61911, 62458, 62579, 67165, 69195, 70721, 72260, 72282,
  72427, 75084, 75917, 75923, 77277, 77283, 77741, 79774, 80008, 85472
]
# rubocop:enable Style/NumericLiterals, Layout/MultilineArrayLineBreaks

InductionPeriod.where(id: induction_periods_to_delete).delete_all
