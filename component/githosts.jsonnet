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
    stringData:
      local gh = params.githosts[name];
      {
        endpoint: gh.endpoint,
        token: gh.token,
        hostKeys: gh.host_keys,
        [if std.objectHas(gh, 'ssh_endpoint') then 'sshEndpoint']: std.get(gh, gh.ssh_endpoint),
      },
  }
  for name in std.objectFields(params.githosts)
}
