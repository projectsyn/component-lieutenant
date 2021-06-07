local kap = import 'lib/kapitan.libjsonnet';
local kube = import 'lib/kube.libjsonnet';
local inv = kap.inventory();
// The hiera parameters for the component
local params = inv.parameters.lieutenant;

local role = std.parseJson(kap.yaml_load('lieutenant/manifests/api/role.yaml'));
local service_account = std.parseJson(kap.yaml_load('lieutenant/manifests/api/service_account.yaml'));
local role_binding = std.parseJson(kap.yaml_load('lieutenant/manifests/api/role_binding.yaml'));
local deployment = std.parseJson(kap.yaml_load('lieutenant/manifests/api/deployment.yaml'));
local service = std.parseJson(kap.yaml_load('lieutenant/manifests/api/service.yaml'));

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
  },
};


local objects = [
  role,
  service_account,
  role_binding,
  service,
  deployment {
    spec+: {
      template+: {
        spec+: {
          containers: [ deployment.spec.template.spec.containers[0] {
            env+: [
              {
                name: 'DEFAULT_API_SECRET_REF_NAME',
                value: params.api.default_githost,
              },
              {
                name: 'STEWARD_IMAGE',
                value: params.api.steward_image,
              },
            ],
          } ],
        },
      },
    },
  },
  ingress,
];


{
  ['%s' % [ std.asciiLower(obj.kind) ]]: obj {
    metadata+: {
      namespace: params.namespace,
    },
  }
  for obj in objects
}
