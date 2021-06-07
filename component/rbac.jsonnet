local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.lieutenant;

{
  ['%s' % [ std.asciiLower(a.name) ]]: kube.RoleBinding(a.name) {
    metadata: {
      name: a.name,
      namespace: params.namespace,
    },
    roleRef: {
      kind: 'Role',
      apiGroup: 'rbac.authorization.k8s.io',
      name: a.tenant,
    },
    subjects: a.subjects,

  }
  for a in params.tenant_access
}
