local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.lieutenant;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('lieutenant', params.namespace);

{
  lieutenant: app,
}
