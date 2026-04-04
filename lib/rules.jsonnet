// Generates recording rules for a single mixin.
// Called with --ext-str mixin=<name> to select which mixin to build.
// Use -S flag for string output (YAML).

local mixins = import 'mixins.libsonnet';
local mixinName = std.extVar('mixin');

if std.objectHasAll(mixins[mixinName], 'prometheusRules')
then std.manifestYamlDoc(mixins[mixinName].prometheusRules)
else ''
