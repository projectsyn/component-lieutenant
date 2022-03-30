package main

import (
	"fmt"
	"io/ioutil"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	appv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	netv1 "k8s.io/api/networking/v1"
	rbacv1 "k8s.io/api/rbac/v1"
	"sigs.k8s.io/yaml"
)

func Test_APIDeployment(t *testing.T) {
	deploy := &appv1.Deployment{}
	data, err := ioutil.ReadFile(testPath + "/20_api/deployment-lieutenant-api.yaml")
	require.NoError(t, err)
	err = yaml.UnmarshalStrict(data, deploy)
	require.NoError(t, err)

	assert.Equal(t, api, deploy.Name)
	assert.Equal(t, namespace, deploy.Namespace)

	require.NotEmpty(t, deploy.Spec.Template.Spec.Containers)
	assert.Len(t, deploy.Spec.Template.Spec.Containers, 1)
	c := deploy.Spec.Template.Spec.Containers[0]
	assert.Equal(t, apiImage, c.Image)
	assert.Len(t, c.Env, 6)

	for _, env := range c.Env {
		switch env.Name {
		case "STEWARD_IMAGE":
			assert.Equal(t, stewardImage, env.Value)
		case "DEFAULT_API_SECRET_REF_NAME":
			assert.Equal(t, defaultGithost, env.Value)
		}
	}

}

func Test_APIIngress(t *testing.T) {
	ing := &netv1.Ingress{}
	data, err := ioutil.ReadFile(testPath + "/20_api/ingress-lieutenant-api.yaml")
	require.NoError(t, err)
	err = yaml.UnmarshalStrict(data, ing)
	require.NoError(t, err)
	assert.Equal(t, api, ing.Name)
	assert.Equal(t, namespace, ing.Namespace)

	svc := &corev1.Service{}
	data, err = ioutil.ReadFile(testPath + "/20_api/service-lieutenant-api.yaml")
	require.NoError(t, err)
	err = yaml.UnmarshalStrict(data, svc)
	require.NoError(t, err)
	assert.Equal(t, api, svc.Name)
	assert.Equal(t, namespace, svc.Namespace)

	require.NotEmpty(t, ing.Spec.Rules)
	assert.Equal(t, "lieutenant.todo", ing.Spec.Rules[0].Host)
	require.NotEmpty(t, ing.Spec.Rules[0].HTTP.Paths)
	p := ing.Spec.Rules[0].HTTP.Paths[0]
	require.Equal(t, "/", p.Path)
	require.Equal(t, svc.Name, p.Backend.Service.Name)

	require.NotEmpty(t, ing.Spec.TLS)
	require.NotEmpty(t, ing.Spec.TLS[0].Hosts)
	assert.Equal(t, ing.Spec.Rules[0].Host, ing.Spec.TLS[0].Hosts[0])

	deploy := &appv1.Deployment{}
	data, err = ioutil.ReadFile(testPath + "/20_api/deployment-lieutenant-api.yaml")
	require.NoError(t, err)
	err = yaml.UnmarshalStrict(data, deploy)
	require.NoError(t, err)

	assert.Equal(t, deploy.Spec.Selector.MatchLabels, svc.Spec.Selector)
}

func Test_APIRBAC(t *testing.T) {
	role := &rbacv1.Role{}
	data, err := ioutil.ReadFile(testPath + "/20_api/role-lieutenant-api.yaml")
	require.NoError(t, err)
	err = yaml.UnmarshalStrict(data, role)
	require.NoError(t, err)

	assert.Equal(t, api, role.Name)
	assert.Equal(t, namespace, role.Namespace)

	rolebinding := &rbacv1.RoleBinding{}
	data, err = ioutil.ReadFile(testPath + "/20_api/rolebinding-lieutenant-api.yaml")
	require.NoError(t, err)
	err = yaml.UnmarshalStrict(data, rolebinding)
	require.NoError(t, err)

	assert.Equal(t, api, rolebinding.Name)
	assert.Equal(t, namespace, rolebinding.Namespace)

	sa := &corev1.ServiceAccount{}
	data, err = ioutil.ReadFile(testPath + "/20_api/serviceaccount-lieutenant-api.yaml")
	require.NoError(t, err)
	err = yaml.UnmarshalStrict(data, sa)
	require.NoError(t, err)

	assert.Equal(t, api, sa.Name)
	assert.Equal(t, namespace, sa.Namespace)

	assert.Equal(t, role.Name, rolebinding.RoleRef.Name, "RoleBinding is not referencing the Role")
	require.NotEmpty(t, rolebinding.Subjects)
	assert.Len(t, rolebinding.Subjects, 1, "RoleBinding is referencing unknown Subjects")
	assert.Equal(t, sa.Name, rolebinding.Subjects[0].Name, "RoleBinding is not referencing the ServiceAccount")
}

func Test_APIUserRBAC(t *testing.T) {
	apiUser := "lieutenant-api-user"
	role := &rbacv1.Role{}
	data, err := ioutil.ReadFile(testPath + "/20_api/role-lieutenant-api-user.yaml")
	require.NoError(t, err)
	err = yaml.UnmarshalStrict(data, role)
	require.NoError(t, err)

	assert.Equal(t, apiUser, role.Name)
	assert.Equal(t, namespace, role.Namespace)

	rolebinding := &rbacv1.RoleBinding{}
	data, err = ioutil.ReadFile(testPath + "/20_api/rolebinding-lieutenant-api-user.yaml")
	require.NoError(t, err)
	err = yaml.UnmarshalStrict(data, rolebinding)
	require.NoError(t, err)

	assert.Equal(t, apiUser, rolebinding.Name)
	assert.Equal(t, namespace, rolebinding.Namespace)

	assert.Equal(t, role.Name, rolebinding.RoleRef.Name, "RoleBinding is not referencing the Role")
	require.NotEmpty(t, rolebinding.Subjects, "No API users specified")

	for _, sub := range rolebinding.Subjects {
		if sub.Kind == rbacv1.ServiceAccountKind {
			sa := &corev1.ServiceAccount{}
			data, err = ioutil.ReadFile(fmt.Sprintf("%s/20_api/serviceaccount-%s.yaml", testPath, sub.Name))
			require.NoError(t, err, "ServiceAccount does not exist")
			err = yaml.UnmarshalStrict(data, sa)
			require.NoError(t, err)

			assert.Equal(t, sub.Name, sa.Name)
			assert.Equal(t, namespace, sa.Namespace)
		}
	}

}
