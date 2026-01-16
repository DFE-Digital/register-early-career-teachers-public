# From all the induction records of a participant received in the converter, the latest induction records mode will
# group them by (school, lead provider, cohort) and select the one unfinished or the most recently created one.
# The resulting list will be sorted by start_date, created_at, unfinished last. See TeacherHistoryConverter::CalculatedFields
# The next 2 consecutive pair of blocks (from the resulting list resulting above) is a different test case we want to test here:
#
#                                             ┌───────────────────────┐
#                                             │                       │
#                                             └───────────────────────┘
#                                             ┌────────────────────┐
#                                             │                    │
#                                             └────────────────────┘
#                                             ┌────────────────────┐
#                                             │                    │
#                                             └────────────────────┘
#                            ┌────────────────────┐
#                            │                    │
#                            └────────────────────┘
#  ┌────────────────────┐
#  │                    │
#  └────────────────────┘
#  ┌─────────────────────────┐
#  │                         │
#  └─────────────────────────┘
#     ┌─────────────────┐
#     │                 │
#     └─────────────────┘
#       ┌───────────────┐
#       │               │
#       └───────────────┘
#         ┌───────────────────────┐
#         │                       │
#         └───────────────────────┘
#            ┌────────────────────────>
#            │
#            └────────────────────────>

#   OR

#                     ...
#         ┌───────────────────────┐
#         │                       │
#         └───────────────────────┘
#         ┌──────────────────────────────>
#         │
#         └──────────────────────────────>

#    OR
#                     ...
#         ┌───────────────────────┐
#         │                       │
#         └───────────────────────┘
#      ┌──────────────────────────────>
#      │
#      └──────────────────────────────>
