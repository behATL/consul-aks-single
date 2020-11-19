# none of this works. Regex isn't supported.

Kind = "service-router"
Name = "currency-all"
Routes = [
  {
    Match {
      HTTP {
        pathRegex = "/v2(.*)"
      }
    }
    Destination {
      Service = "currency-v2"
      Namespace = "default"
      PrefixRewrite = "?1"
    }
  },
]
