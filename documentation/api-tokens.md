# API tokens

## Development/review

We generate tokens for each lead provider in the review apps (via the development database seeds) to make testing easier. The tokens are the lead provider names, lower case and hyphenated:

```
Ambition Institute              => ambition-institute
Best Practice Network           => best-practice-network
Capita                          => capita
Education Development Trust     => education-development-trust
National Institute of Teaching  => national-institute-of-teaching
Teach First                     => teach-first
UCL Institute of Education      => ucl-institute-of-education
```

## Staging

The staging tokens are currently configured as above; the lead provider name lower case and hyphenated.  

## Sandbox

The sandbox tokens have been distributed to lead providers via galaxkey and are also available in [this spreadsheet](https://educationgovuk.sharepoint.com/:x:/r/sites/TeacherServices/Shared%20Documents/Teacher%20Continuing%20Professional%20Development/Teacher%20CPD%20Team/Register%20early%20career%20teachers/Beta/Dev/RECT%20API%20tokens.xlsx?d=w645914cfeed84fddbeb4a31e1ade1bbf&csf=1&web=1&e=VPmgan).

## Production

At the time of writing, there are no lead provider records in production as we have not yet migrated the data across from ECF.
