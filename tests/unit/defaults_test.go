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

	operator      = "lieutenant-operator"
	operatorImage = "docker.io/projectsyn/lieutenant-operator:v0.5.3"

	api            = "lieutenant-api"
	apiImage       = "docker.io/projectsyn/lieutenant-api:v0.6.0"
	stewardImage   = "docker.io/projectsyn/steward:v0.3.1"
	defaultGithost = "gitlab-com"
)

// kubeval is unable to validate some of the resources
// we need to explicitly ignore them
func skipValidation(path string) bool {
	ignore := []string{
		fmt.Sprintf("%s/00_crds", testPath),
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
	data, err := ioutil.ReadFile(testPath + "/01_namespace.yaml")
	require.NoError(t, err)
	err = yaml.Unmarshal(data, &ns)
	require.NoError(t, err)
	assert.Equal(t, "lieutenant", ns.Name)
}
