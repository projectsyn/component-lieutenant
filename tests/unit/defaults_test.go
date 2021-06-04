package main

import (
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

func Test_Namespace(t *testing.T) {
	ns := corev1.Namespace{}
	data, err := ioutil.ReadFile(testPath + "/namespace.yaml")
	require.NoError(t, err)
	err = yaml.Unmarshal(data, &ns)
	require.NoError(t, err)
	assert.Equal(t, "lieutenant", ns.Name)
}
