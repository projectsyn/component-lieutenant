local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.lieutenant;

local role = std.parseJson(kap.yaml_load('lieutenant/manifests/api/' + params.api.manifest_version + '/role.yaml'));
local service_account = std.parseJson(kap.yaml_load('lieutenant/manifests/api/' + params.api.manifest_version + '/service_account.yaml'));
local role_binding = std.parseJson(kap.yaml_load('lieutenant/manifests/api/' + params.api.manifest_version + '/role_binding.yaml'));
local deployment = std.parseJson(kap.yaml_load('lieutenant/manifests/api/' + params.api.manifest_version + '/deployment.yaml'));
local raw_service = std.parseJson(kap.yaml_load('lieutenant/manifests/api/' + params.api.manifest_version + '/service.yaml'));
local service = kube.Service(raw_service.metadata.name) {} + raw_service;

local image = params.images.api.registry + '/' + params.images.api.repository + ':' + params.images.api.version;
local steward_image = params.images.steward.registry + '/' + params.images.steward.repository + ':' + params.images.steward.version;

local ingress = kube.Ingress('lieutenant-api') {
  metadata+: std.prune({
    annotations: params.api.ingress.annotations,
  }),
  spec: {
    rules: [
      {
        host: params.api.ingress.host,
        http: {
          paths: [
            {
              path: '/',
              pathType: 'Prefix',
              backend: service.name_port,
            },
          ],
        },
      },
    ],
    tls: if params.api.ingress.tls then
      [
        {
          hosts: [ params.api.ingress.host ],
          secretName: 'lieutenant-api-cert',
        },
      ]
    else
      [],
  },
};

local user_role = kube.Role('lieutenant-api-user') {
  metadata: {
    name: 'lieutenant-api-user',
  },
  rules: [
    {
      apiGroups: [
        'syn.tools',
      ],
      resources: [
        'clusters',
        'clusters/status',
        'tenants',
        'tenants/status',
      ],
      verbs: [
        'create',
        'delete',
        'get',
        'list',
        'patch',
        'update',
        'watch',
      ],
    },
  ],
};

local user_role_binding = kube.RoleBinding('lieutenant-api-user') {
  metadata: {
    name: 'lieutenant-api-user',
  },
  roleRef: {
    kind: 'Role',
    name: user_role.metadata.name,
    apiGroup: 'rbac.authorization.k8s.io',
  },
  subjects: params.api.users,
};

local user_service_accounts = [
  kube.ServiceAccount(u.name) {
    metadata: {
      name: u.name,
    },
  }
  for u in params.api.users
  if u.kind == 'ServiceAccount'
];

local mergeEnvVars(envs, additional) =
  local foldFn =
    function(acc, env)
      acc { [env.name]: env };
  local base = std.foldl(foldFn, envs, {});
  local final = std.foldl(foldFn, additional, base);
  [ final[k] for k in std.objectFields(final) ];

local objects = [
  role,
  service_account,
  role_binding,
  user_role,
  user_role_binding,
  service {
    spec+: {
      selector+: params.api.common_labels,
    },
  },
  deployment {
    spec+: {
      selector+: {
        matchLabels+: params.api.common_labels,
      },
      template+: {
        metadata+: {
          labels+: params.api.common_labels,
        },
        spec+: {
          containers: [
            if c.name == 'lieutenant-api' then
              c {
                image: image,
                env: mergeEnvVars([
                  if e.name == 'STEWARD_IMAGE' then
                    {
                      name: 'STEWARD_IMAGE',
                      value: steward_image,
                    }
                  else if e.name == 'LIEUTENANT_INSTANCE' then
                    {
                      name: 'LIEUTENANT_INSTANCE',
                      value: params.api.lieutenant_instance,
                    }
                  else
                    e
                  for e in super.env + [
                    {
                      name: 'DEFAULT_API_SECRET_REF_NAME',
                      value: params.api.default_githost,
                    },
                  ]
                ], com.envList(params.api.env)),
              }
            else
              c
            for c in super.containers
          ],
        },
      },
    },
  },
  ingress,
] + user_service_accounts;


{
  ['%s-%s' % [ std.asciiLower(obj.kind), std.asciiLower(obj.metadata.name) ]]: obj {
    metadata+: {
      namespace: params.namespace,
      labels+: params.api.common_labels,
    },
  }
  for obj in objects
}
