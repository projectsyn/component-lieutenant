// main template for lieutenant
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.lieutenant;

local namespace = 'lieutenant';
{
  namespace: kube.Namespace(namespace) {
    metadata: {
      name: namespace,
      labels: {
        name: namespace,
      },
    },
  },
}
