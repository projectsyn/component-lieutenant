local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.lieutenant;

local prefix = 'lieutenant-operator-';

local role = std.parseJson(kap.yaml_load('lieutenant/manifests/operator/' + params.operator.manifest_version + '/role.yaml'));
local service_account = std.parseJson(kap.yaml_load('lieutenant/manifests/operator/' + params.operator.manifest_version + '/service_account.yaml'));
local role_binding = std.parseJson(kap.yaml_load('lieutenant/manifests/operator/' + params.operator.manifest_version + '/role_binding.yaml'));
local deployment = std.parseJson(kap.yaml_load('lieutenant/manifests/operator/' + params.operator.manifest_version + '/deployment.yaml'));

local image = params.images.operator.registry + '/' + params.images.operator.repository + ':' + params.images.operator.version;

local objects = [
  role {
    metadata+: {
      name: prefix + super.name,
    },
  },
  role_binding {
    metadata+: {
      name: prefix + super.name,
    },
    roleRef+: {
      name: prefix + super.name,
    },
  },
  service_account,
  deployment {
    metadata+: {
      name: prefix + super.name,
    },
    spec+: {
      selector+: {
        matchLabels+: params.operator.common_labels,
      },
      template+: {
        metadata+: {
          labels+: params.operator.common_labels,
        },
        spec+: {
          containers: [
            if c.name == 'lieutenant-operator' then
              c {
                image: image,
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
                    value: std.toString(params.operator.deletion_protection),
                  },
                  {
                    name: 'SKIP_VAULT_SETUP',
                    value: std.toString(!params.operator.vault.enabled),
                  },
                ] + (
                  if params.operator.vault.enabled then
                    [
                      {
                        name: 'VAULT_ADDR',
                        value: params.operator.vault.addr,
                      },
                      {
                        name: 'VAULT_SECRET_ENGINE_PATH',
                        value: params.operator.vault.path,
                      },
                    ]
                  else []
                ),
              }
            else
              c
            for c in super.containers
          ],
        },
      },
    },
  },
];


{
  [std.asciiLower(obj.kind)]: obj {
    metadata+: {
      namespace: params.namespace,
      labels+: params.operator.common_labels,
    },
  }
  for obj in objects
}
