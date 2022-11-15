local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.lieutenant;

{
  [std.asciiLower(ten)]: kube.RoleBinding('custom-%s' % [ ten ]) {
    metadata+: {
      namespace: params.namespace,
    },
    roleRef: {
      kind: 'Role',
      apiGroup: 'rbac.authorization.k8s.io',
      name: ten,
    },
    subjects: params.tenant_rbac[ten],

  }
  for ten in std.objectFields(params.tenant_rbac)
}
