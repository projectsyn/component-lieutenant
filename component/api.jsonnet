local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.lieutenant;

local role = std.parseJson(kap.yaml_load('lieutenant/manifests/api/' + params.api.manifest_version + '/role.yaml'));
local service_account = std.parseJson(kap.yaml_load('lieutenant/manifests/api/' + params.api.manifest_version + '/service_account.yaml'));
local role_binding = std.parseJson(kap.yaml_load('lieutenant/manifests/api/' + params.api.manifest_version + '/role_binding.yaml'));
local deployment = std.parseJson(kap.yaml_load('lieutenant/manifests/api/' + params.api.manifest_version + '/deployment.yaml'));
local service = std.parseJson(kap.yaml_load('lieutenant/manifests/api/' + params.api.manifest_version + '/service.yaml'));

local image = params.images.api.registry + '/' + params.images.api.repository + ':' + params.images.api.version;
local steward_image = params.images.steward.registry + '/' + params.images.steward.repository + ':' + params.images.steward.version;

local ingress = kube.Ingress('lieutenant-api') {
  metadata: std.prune({
    name: 'lieutenant-api',
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
              backend: {
                serviceName: service.metadata.name,
                servicePort: 80,
              },
            },
          ],
        },
      },
    ],
    tls: [
      {
        hosts: [ params.api.ingress.host ],
        secretName: 'lieutenant-api-cert',
      },
    ],
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
        'tenants',
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
                env: [
                  if e.name == 'STEWARD_IMAGE' then
                    {
                      name: 'STEWARD_IMAGE',
                      value: steward_image,
                    }
                  else
                    e
                  for e in super.env + [
                    {
                      name: 'DEFAULT_API_SECRET_REF_NAME',
                      value: params.api.default_githost,
                    },
                  ]
                ],
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
