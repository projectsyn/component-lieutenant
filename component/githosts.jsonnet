// main template for lieutenant
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.lieutenant;

{
  [std.asciiLower(name)]: kube.Secret(name) {
    metadata+: {
      namespace: params.namespace,
    },
    stringData: {
      endpoint: params.githosts[name].endpoint,
      token: params.githosts[name].token,
      hostKeys: params.githosts[name].host_keys,
    },
  }
  for name in std.objectFields(params.githosts)
}
