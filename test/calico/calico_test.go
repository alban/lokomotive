// Copyright 2020 The Lokomotive Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// +build packet
// +build poste2e

package calico

import (
	"encoding/json"
	"testing"

	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured/unstructuredscheme"
	"k8s.io/apimachinery/pkg/runtime/schema"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"

	"github.com/kinvolk/lokomotive/test/components/util"
)

func TestHostEndpoints(t *testing.T) {
	// Build rest client so we can do equivalent of 'kubectl get --raw'.
	config, err := clientcmd.BuildConfigFromFlags("", util.KubeconfigPath(t))
	if err != nil {
		t.Fatalf("failed building rest client config: %v", err)
	}

	config.GroupVersion = &schema.GroupVersion{}
	config.NegotiatedSerializer = unstructuredscheme.NewUnstructuredNegotiatedSerializer()

	client, err := rest.RESTClientFor(config)
	if err != nil {
		t.Fatalf("failed building rest client: %v", err)
	}

	// This is minimal version of Calico HostEndpoint CRD object which we need to deserialize
	// from raw JSON.
	hostEndpoints := struct {
		Items []struct {
			Spec struct {
				Node string
			}
		}
	}{}

	request := client.Get()
	request.RequestURI("apis/crd.projectcalico.org/v1/hostendpoints")
	response, err := request.DoRaw()
	if err != nil {
		t.Fatalf("failed getting HostEndpoint objects: %v", err)
	}

	if err := json.Unmarshal(response, &hostEndpoints); err != nil {
		t.Fatalf("failed unmarshalling response: %v\n\n%s", err, string(response))
	}

	// Collect all received host endpoints into a map, so we can quickly look up if
	// specific object exists. We combine Node name and interface name to ensure, that
	// HostEndpoint objects are created for all nodes and for right interfaces.
	endpoints := map[string]struct{}{}

	for _, v := range hostEndpoints.Items {
		endpoints[v.Spec.Node] = struct{}{}
	}

	cs := util.CreateKubeClient(t)

	nodes, err := cs.CoreV1().Nodes().List(metav1.ListOptions{})
	if err != nil {
		t.Fatalf("failed getting list of nodes in the cluster: %v", err)
	}

	for _, v := range nodes.Items {
		if _, ok := endpoints[v.Name]; !ok {
			t.Errorf("no HostEndpoint object found for node %q", v.Name)
		}
	}
}
