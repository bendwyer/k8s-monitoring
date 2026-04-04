// Combined mixin output — merges all mixins from lib/mixins.libsonnet.
// Used by legacy combined alerts/rules targets if needed.
// Individual per-mixin builds use lib/mixins.libsonnet directly.

local mixins = import 'lib/mixins.libsonnet';
local config = import 'lib/config.libsonnet';

std.foldl(
  function(acc, name) acc + mixins[name],
  std.objectFields(mixins),
  {}
) + { _config+:: config }
