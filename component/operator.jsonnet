local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.lieutenant;

local role = std.parseJson(kap.yaml_load('lieutenant/manifests/operator/role.yaml'));
local service_account = std.parseJson(kap.yaml_load('lieutenant/manifests/operator/service_account.yaml'));
local role_binding = std.parseJson(kap.yaml_load('lieutenant/manifests/operator/role_binding.yaml'));
local deployment = std.parseJson(kap.yaml_load('lieutenant/manifests/operator/deployment.yaml'));


local objects = [
  role,
  service_account,
  role_binding,
  deployment {
    spec+: {
      template+: {
        spec+: {
          containers: [ deployment.spec.template.spec.containers[0] {
            env+: [
              {
                name: 'DEFAULT_DELETION_POLICY',
                value: params.operator.default_deletion_policy,
              },
              {
                name: 'DEFAULT_GLOBAL_GIT_REPO_URL',
                value: params.operator.default_global_git_repo,
              },
              {
                name: 'LIEUTENANT_DELETE_PROTECTION',
                value: params.operator.deletion_protection,
              },
              {
                name: 'SKIP_VAULT_SETUP',
                value: !params.operator.vault.enabled,
              },
            ] + (
              if params.operator.vault.enabled then [
                {
                  name: 'VAULT_ADDR',
                  value: params.operator.vault.addr,
                },
                {
                  name: 'VAULT_SECRET_ENGINE_PATH',
                  value: params.operator.vault.path,
                },
              ] else []
            ),
          } ],
        },
      },
    },
  },
];


{
  ['%s' % [ std.asciiLower(obj.kind) ]]: obj {
    metadata+: {
      namespace: params.namespace,
    },
  }
  for obj in objects
}
