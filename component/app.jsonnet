local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.lieutenant;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('lieutenant', params.namespace) {
  spec+: {
    ignoreDifferences+: [
      {
        group: 'apiextensions.k8s.io',
        kind: 'CustomResourceDefinition',
        jsonPointers: [
          '/spec/preserveUnknownFields',
        ],
      },
    ],
  },
};

local appPath =
  local project = std.get(std.get(app, 'spec', {}), 'project', 'syn');
  if project == 'syn' then 'apps' else 'apps-%s' % project;

{
  ['%s/lieutenant' % appPath]: app,
}
