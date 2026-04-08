# DQT Migration

The migration of data from DQT (now TRS) into RIAB has been delivered in two stages.

The second import of legacy data consisting of teachers who had finished training is
scheduled for the second half of 2026.

See <https://github.com/DFE-Digital/register-early-career-teachers-public/pull/1976>.

```sh
# create upload directory on specific pod
$ kubectl exec -i -t -n cpd-production pod/cpd-ec2-production-worker-xxx -- mkdir /app/tmp/import
# upload teacher data
$ kubectl cp ./tmp/import/teachers.csv cpd-production/cpd-ec2-production-worker-xxx:/app/tmp/import/teachers.csv
# upload induction data
$ kubectl cp ./tmp/import/inductionperiods.csv cpd-production/cpd-ec2-production-worker-xxx:/app/tmp/import/inductionperiods.csv
# confirm upload
$ kubectl exec -i -t -n cpd-production pod/cpd-ec2-production-worker-xxx -- ls -lah /app/tmp/import/
# run script
$ kubectl exec -i -t -n cpd-production pod/cpd-ec2-production-worker-xxx -- rails runner db/scripts/importer.rb
```