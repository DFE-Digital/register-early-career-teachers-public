# API tokens

## Development/review

We generate API tokens in the review apps (via the development database seeds) to make testing easier.

### Lead providers

The tokens are the lead provider names, lower case and hyphenated:

```
Ambition Institute              => ambition-institute
Best Practice Network           => best-practice-network
Capita                          => capita
Education Development Trust     => education-development-trust
National Institute of Teaching  => national-institute-of-teaching
Teach First                     => teach-first
UCL Institute of Education      => ucl-institute-of-education
```

### Appropriate bodies

Optionally, we seed AB tokens by setting the `AB_API` env var.
The tokens are the AB name plus third-party name, lower case and hyphenated:

```
Umber using ECT Manager   => umber-teaching-school-hub-ect-manager
Golden Leaf using Moziac  => golden-teaching-school-hub-leaf-mozaic
```

## Staging

- The staging lead provider tokens are configured as above.
- The staging appropriate body tokens are NOT and are generate using the UI.

## Sandbox

The sandbox tokens have been distributed to lead providers via galaxkey and are also available in [this spreadsheet](https://educationgovuk.sharepoint.com/:x:/r/sites/TeacherServices/Shared%20Documents/Teacher%20Continuing%20Professional%20Development/Teacher%20CPD%20Team/Register%20early%20career%20teachers/Beta/Dev/RECT%20API%20tokens.xlsx?d=w645914cfeed84fddbeb4a31e1ade1bbf&csf=1&web=1&e=VPmgan).

## Production

At the time of writing, there are no lead provider records in production as we have not yet migrated the data across from ECF.
