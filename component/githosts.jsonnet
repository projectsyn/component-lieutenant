// main template for lieutenant
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.lieutenant;

{
  ['%s' % [ std.asciiLower(git.name) ]]: kube.Secret(git.name) {
    metadata: {
      name: git.name,
      namespace: params.namespace,
    },
    stringData: {
      endpoint: git.endpoint,
      token: git.token,
      hostKeys: git.host_keys,
    },
  }
  for git in params.githosts
}
