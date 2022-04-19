package main

import (
	"fmt"
	"io/ioutil"
	"testing"

	"github.com/instrumenta/kubeval/kubeval"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	corev1 "k8s.io/api/core/v1"
	"sigs.k8s.io/yaml"
)

var (
	testPath = "../../compiled/lieutenant/lieutenant"

	namespace = "lieutenant"

	operator      = "lieutenant-operator-controller-manager"
	operatorImage = "quay.io/projectsyn/lieutenant-operator:1.3.0"

	api            = "lieutenant-api"
	apiImage       = "docker.io/projectsyn/lieutenant-api:v0.9.0"
	stewardImage   = "docker.io/projectsyn/steward:v0.7.0"
	defaultGithost = "gitlab-com"
)

// kubeval is unable to validate some of the resources
// we need to explicitly ignore them
func skipValidation(path string) bool {
	ignore := []string{
		fmt.Sprintf("%s/00_crds", testPath),
		fmt.Sprintf("%s/20_api/ingress-lieutenant-api.yaml", testPath),
		fmt.Sprintf("%s/60_tenant_template.yaml", testPath),
	}
	for _, iv := range ignore {
		if iv == path {
			return true
		}
	}
	return false
}

func validate(t *testing.T, path string) {
	files, err := ioutil.ReadDir(path)
	require.NoError(t, err)
	for _, file := range files {
		filePath := fmt.Sprintf("%s/%s", path, file.Name())
		if skipValidation(filePath) {
			continue
		}
		if file.IsDir() {
			validate(t, filePath)
		} else {
			data, err := ioutil.ReadFile(filePath)
			require.NoError(t, err)

			conf := kubeval.NewDefaultConfig()
			res, err := kubeval.Validate(data, conf)
			require.NoError(t, err)
			for _, r := range res {
				if len(r.Errors) > 0 {
					t.Errorf("%s", filePath)
				}
				for _, e := range r.Errors {
					t.Errorf("\t %s", e)
				}
			}
		}
	}
}
func Test_Validate(t *testing.T) {
	validate(t, testPath)
}

func Test_CRDs(t *testing.T) {
	crds := []string{
		"syn.tools_clusters.yaml",
		"syn.tools_gitrepos.yaml",
		"syn.tools_tenants.yaml",
		"syn.tools_tenanttemplates.yaml",
	}
	for _, crd := range crds {
		_, err := ioutil.ReadFile(fmt.Sprintf("%s/00_crds/%s", testPath, crd))
		require.NoError(t, err)
		// TODO(glrf): do something more useful than just checking if they exist
	}
}

func Test_Namespace(t *testing.T) {
	ns := corev1.Namespace{}
	data, err := ioutil.ReadFile(testPath + "/01_namespace.yaml")
	require.NoError(t, err)
	err = yaml.Unmarshal(data, &ns)
	require.NoError(t, err)
	assert.Equal(t, "lieutenant", ns.Name)
}
