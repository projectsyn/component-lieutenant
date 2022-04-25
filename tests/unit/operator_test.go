package main

import (
	"io/ioutil"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	appv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
	rbacv1 "k8s.io/api/rbac/v1"
	"sigs.k8s.io/yaml"
)

func Test_OperatorDeployment(t *testing.T) {
	deploy := &appv1.Deployment{}
	data, err := ioutil.ReadFile(testPath + "/10_operator/deployment.yaml")
	require.NoError(t, err)
	err = yaml.UnmarshalStrict(data, deploy)
	require.NoError(t, err)

	assert.Equal(t, operator, deploy.Name)
	assert.Equal(t, namespace, deploy.Namespace)

	require.NotEmpty(t, deploy.Spec.Template.Spec.Containers)
	assert.Len(t, deploy.Spec.Template.Spec.Containers, 1)
	c := deploy.Spec.Template.Spec.Containers[0]
	assert.Len(t, c.Env, 10)
}

func Test_OperatorRBAC(t *testing.T) {
	role := &rbacv1.Role{}
	data, err := ioutil.ReadFile(testPath + "/10_operator/clusterrole.yaml")
	require.NoError(t, err)
	err = yaml.UnmarshalStrict(data, role)
	require.NoError(t, err)

	assert.Equal(t, "lieutenant-operator-manager-role", role.Name)
	assert.Equal(t, namespace, role.Namespace)

	rolebinding := &rbacv1.RoleBinding{}
	data, err = ioutil.ReadFile(testPath + "/10_operator/clusterrolebinding.yaml")
	require.NoError(t, err)
	err = yaml.UnmarshalStrict(data, rolebinding)
	require.NoError(t, err)

	assert.Equal(t, "lieutenant-operator-manager-rolebinding", rolebinding.Name)
	assert.Equal(t, namespace, rolebinding.Namespace)
	assert.Equal(t, namespace, rolebinding.Subjects[0].Namespace)

	sa := &corev1.ServiceAccount{}
	data, err = ioutil.ReadFile(testPath + "/10_operator/serviceaccount.yaml")
	require.NoError(t, err)
	err = yaml.UnmarshalStrict(data, sa)
	require.NoError(t, err)

	assert.Equal(t, "lieutenant-operator", sa.Name)
	assert.Equal(t, namespace, sa.Namespace)

	assert.Equal(t, role.Name, rolebinding.RoleRef.Name, "RoleBinding is not referencing the Role")
	require.NotEmpty(t, rolebinding.Subjects)
	assert.Len(t, rolebinding.Subjects, 1, "RoleBinding is referencing unknown Subjects")
	assert.Equal(t, sa.Name, rolebinding.Subjects[0].Name, "RoleBinding is not referencing the ServiceAccount")
}
