local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.lieutenant;

local common = import 'common.libsonnet';

local prefix = 'lieutenant-operator-';

local role = std.parseJson(kap.yaml_load('lieutenant/manifests/operator/' + params.operator.manifest_version + '/role.yaml'));
local service_account = std.parseJson(kap.yaml_load('lieutenant/manifests/operator/' + params.operator.manifest_version + '/service_account.yaml'));
local role_binding = std.parseJson(kap.yaml_load('lieutenant/manifests/operator/' + params.operator.manifest_version + '/role_binding.yaml'));
local deployment = std.parseJson(kap.yaml_load('lieutenant/manifests/operator/' + params.operator.manifest_version + '/deployment.yaml'));

local image = params.images.operator.registry + '/' + params.images.operator.repository + ':' + params.images.operator.version;


local default_env =
  {
    DEFAULT_DELETION_POLICY: params.operator.default_deletion_policy,
    DEFAULT_GLOBAL_GIT_REPO_URL: params.operator.default_global_git_repo,
    LIEUTENANT_DELETE_PROTECTION: params.operator.deletion_protection,
    SKIP_VAULT_SETUP: !params.operator.vault.enabled,
  } +
  if params.operator.vault.enabled then
    {
      VAULT_ADDR: params.operator.vault.addr,
      VAULT_AUTH_PATH: params.operator.vault.auth_path,
      VAULT_SECRET_ENGINE_PATH: params.operator.vault.path,
    }
  else
    {};

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
    subjects: std.map(function(s) s {
      namespace: params.namespace,
    }, super.subjects),
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
                env: common.MergeEnvVars(
                  super.env,
                  com.envList(default_env + params.operator.env)
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
