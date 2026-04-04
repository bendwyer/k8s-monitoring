# k8s-monitoring

Builds monitoring dashboards, alerts, and recording rules from upstream [monitoring mixins](https://monitoring.mixins.dev/) and publishes them as Flux OCI artifacts.

## Adding a mixin

1. Install the dependency:
   ```sh
   jb install github.com/<org>/<repo>/<subdir>@<version>
   ```
2. Add the import to `lib/mixins.libsonnet`:
   ```jsonnet
   '<mixin-name>': withConfig(import '<vendor-path>/mixin.libsonnet'),
   ```
3. Build and verify:
   ```sh
   make generate
   ```

## Removing a mixin

1. Remove the import from `lib/mixins.libsonnet`
2. Remove the dependency from `jsonnetfile.json`
3. Run `jb install` to update the lock file
4. Build and verify:
   ```sh
   make generate
   ```

## Adding a static dashboard

1. Add the dashboard JSON file to `dashboards-static/`
2. Add an entry to `dashboards-static/manifest.json`:
   ```json
   "<artifact-name>": {
     "version": "1.0.0",
     "files": ["<filename>.json"]
   }
   ```
3. Build and verify:
   ```sh
   make generate
   ```

## Removing a static dashboard

1. Remove the entry from `dashboards-static/manifest.json`
2. Delete the JSON file from `dashboards-static/`

## Local build

Requires [jsonnet](https://github.com/google/go-jsonnet), [jsonnet-bundler](https://github.com/jsonnet-bundler/jsonnet-bundler), and [jq](https://jqlang.github.io/jq/).

```sh
make generate
```

Output:
- `dashboards_out/<mixin>/` — Grafana dashboard JSON files
- `alerts_out/<mixin>/alerts.yml` — Prometheus alerting rules
- `rules_out/<mixin>/rules.yml` — Prometheus recording rules
