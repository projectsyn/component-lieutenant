package main

import (
	"fmt"
	"io/ioutil"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	rbacv1 "k8s.io/api/rbac/v1"
	"sigs.k8s.io/yaml"
)

func Test_RBAC(t *testing.T) {
	tenants := map[string][]rbacv1.Subject{
		"t-foo-124": {
			{
				Name: "u-bar-1",
				Kind: rbacv1.UserKind,
			},
		},
		"t-foo-324": {
			{
				Name: "u-bar-1",
				Kind: rbacv1.UserKind,
			},
			{
				Name: "u-bar-2",
				Kind: rbacv1.UserKind,
			},
		},
		"t-foo-1": {
			{
				Name: "u-bar-2",
				Kind: rbacv1.UserKind,
			},
			{
				Name: "g-buzz",
				Kind: rbacv1.GroupKind,
			},
		},
	}

	for ten, sub := range tenants {
		rb := &rbacv1.RoleBinding{}
		data, err := ioutil.ReadFile(fmt.Sprintf("%s/40_rbac/%s.yaml", testPath, ten))
		require.NoError(t, err)
		err = yaml.UnmarshalStrict(data, rb)
		require.NoError(t, err)

		assert.Equal(t, ten, rb.Name)
		assert.Equal(t, namespace, rb.Namespace)
		assert.ElementsMatch(t, sub, rb.Subjects)
	}
}
