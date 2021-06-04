package main

import (
	"fmt"
	"io/ioutil"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	corev1 "k8s.io/api/core/v1"
	"sigs.k8s.io/yaml"
)

var (
	testPath = "../../compiled/lieutenant/lieutenant"
)

func Test_CRDs(t *testing.T) {
	crds := []string{
		"syn.tools_clusters_crd.yaml",
		"syn.tools_gitrepos_crd.yaml",
		"syn.tools_tenants_crd.yaml",
		"syn.tools_tenanttemplates_crd.yaml",
	}
	for _, crd := range crds {
		_, err := ioutil.ReadFile(fmt.Sprintf("%s/00_crds/%s", testPath, crd))
		require.NoError(t, err)
		// TODO(glrf): do something more useful than just checking if they exist
	}
}

func Test_Namespace(t *testing.T) {
	ns := corev1.Namespace{}
	data, err := ioutil.ReadFile(testPath + "/namespace.yaml")
	require.NoError(t, err)
	err = yaml.Unmarshal(data, &ns)
	require.NoError(t, err)
	assert.Equal(t, "lieutenant", ns.Name)
}
