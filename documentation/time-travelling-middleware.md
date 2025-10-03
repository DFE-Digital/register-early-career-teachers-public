# Time travelling middleware

We have `API::TimeTravelerMiddleware` that we load into all non-production environments. This allows us to simulate a specific 'current date' on the server and make requests as if its that date, which is useful for debugging and testing specific scenarios that are date-sensitive.

In order to make a request on a specific date, you need to pass the `X-WITH-SERVER-DATE` header with the date in ISO 8601 format, for example:

```
X-WITH-SERVER-DATE: 2021-08-08T10:10:00+01:00
```

Note that Rack will normalise incoming HTTP headers into the Rack environment by prefixing with `HTTP_` and converting hyphens to underscores, which is why the middleware checks for `HTTP_X_WITH_SERVER_DATE`.
