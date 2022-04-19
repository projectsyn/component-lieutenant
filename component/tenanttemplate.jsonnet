local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.lieutenant;

local tenanttemplate =
  if params.tenant_template != null then
    kube._Object('syn.tools/v1alpha1', 'TenantTemplate', 'default') {
      metadata+: {
        labels+: params.operator.common_labels,
      },
      spec: params.tenant_template,
    };

{
  [if tenanttemplate != null then '60_tenant_template']: tenanttemplate,
}
