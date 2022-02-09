# Current Limitations

- Base station to ThingPark Enterprise traffic is encrypted using TLS. IPSec is no longer supported
- TLS activation is not supported by SUPLOG in the current release. Hence, activating TLS requires a custom base station image.
- Current installation require 3 workers nodes.
- Only one ThingPark Enterprise instance deployment per cluster have been validated
- Galera cluster failure recovery is a manual procedure
