local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.lieutenant;

local sub = [
  params.auth_delegation[name]
  for name in std.objectFields(params.auth_delegation)
];

{
  [if std.length(sub) > 0 then '50_auth_delegation']: kube.ClusterRoleBinding('syn-lieutenant:auth-delegation') {
    roleRef: {
      apiGroup: 'rbac.authorization.k8s.io',
      kind: 'ClusterRole',
      name: 'system:auth-delegator',
    },
    subjects: sub,
  },
}
