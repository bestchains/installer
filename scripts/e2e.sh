#!/usr/bin/env bash
#
# Copyright contributors to the Hyperledger Fabric Operator project
#
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at:
#
# 	  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# variants for options
UPGRADE_U4A=${UPGRADE_U4A:-"NO"}
INSTALL_U4A=${INSTALL_U4A:-"NO"}

REMOVE_FABRIC_OPERATOR=${REMOVE_FABRIC_OPERATOR:-"NO"}
UPGRADE_FABRIC_OPERATOR=${UPGRADE_FABRIC_OPERATOR:-"NO"}
IGNORE_FABRIC_OPERATOR=${IGNORE_FABRIC_OPERATOR:-"YES"}


TIMEOUT=${TIMEOUT:-"1200s"}
WAIT_TEKTON_INSTALL=${WAIT_TEKTON_INSTALL:-"YES"}
RUN_TEKTON_EXAMPLE=${RUN_TEKTON_EXAMPLE:-"YES"}

echo "checking option params..."

# Get install options
for i in "$@"; do
	echo $i
	if [ $i == "--all" ];
	then
		echo "will install all parts by default"
		INSTALL_U4A="YES"
		IGNORE_FABRIC_OPERATOR="NO"
	elif [ $i == "--u4a" ];
	then 
		echo "will install u4a components"
		INSTALL_U4A="YES"
	elif [ $i == "--baas" ];
	then
		echo "will install fabric-operator"
		IGNORE_FABRIC_OPERATOR="NO"
	elif [ $i == "--addon" ];
	then
		echo "will install addons"
		# TODO: future components integration
	elif [ $i == "--up-all" ];
	then
		echo "will upgrade all components"
		UPGRADE_U4A="YES"
		UPGRADE_FABRIC_OPERATOR="YES"
		# TODO: upgrade other components
	elif [ $i == "--up-baas" ];
	then
		echo "will upgrade fabric-operator"
		UPGRADE_FABRIC_OPERATOR="YES"
	elif [ $i == "--rm-baas" ];
	then
		echo "will remove fabric-operator"
		REMOVE_FABRIC_OPERATOR="YES"
	else
		echo "param error, no changes applied"
	fi
done

function debug() {
	kubectl describe po -A
	kubectl get po -A
	exit 1
}
trap debug ERR

# step 1. create namespace
if [ $INSTALL_U4A == "YES" ]; then
	kubectl create namespace u4a-system
fi

# step 2. get node name and node ip
ingressNode="kind-worker"
kubeProxyNode="kind-worker2"
ingressNodeIP=$(kubectl get node ${ingressNode} -owide | grep -v "NAME" | awk '{print $6}')
kubeProxyNodeIP=$(kubectl get node ${kubeProxyNode} -owide | grep -v "NAME" | awk '{print $6}')

echo "node info:"
kubectl get node -o wide
echo "ingressNodeIp is: ${ingressNodeIP}"
echo "kubeProxyNodeIP is: ${kubeProxyNodeIP}"
export ingressNodeIP=${ingressNodeIP}

# step 3. repalce ingress node name
cat u4a-component/charts/cluster-component/values.yaml | sed "s/<replaced-ingress-node-name>/${ingressNode}/g" \
	>u4a-component/charts/cluster-component/values1.yaml

# step 4. replace nginx and kube proxy node name
cat u4a-component/values.yaml | sed "s/<replaced-ingress-nginx-ip>/${ingressNodeIP}/g" |
	sed "s/<replaced-oidc-proxy-node-name>/${kubeProxyNode}/g" |
	sed "s/<replaced-k8s-ip-with-oidc-enabled>/${kubeProxyNodeIP}/g" \
		>u4a-component/values1.yaml
		
if [ $INSTALL_U4A == "YES" ]; then
# step 5. install cluster-compoent
	echo "begin deploying cluster component..."
	helm --wait --timeout=$TIMEOUT -n u4a-system install cluster-component --wait -f u4a-component/charts/cluster-component/values1.yaml u4a-component/charts/cluster-component
	echo "deploy cluster component succeffsully."

# step 6. install u4a component
	echo "begin deploying u4a component..."
	helm --wait --timeout=$TIMEOUT -n u4a-system install u4a-component --wait -f u4a-component/values1.yaml u4a-component
	echo "deploy u4a component successfully"

echo "namespace info:"
kubectl get po -n u4a-system -o wide
fi

# baas step 1. replace iam server and get oidc-server client secret
secret=$(kubectl get cm oidc-server -nu4a-system -oyaml | grep secret | head -n1 | awk '{print $2}')

cat fabric-operator/values.yaml | sed "s/<replaced-ingress-nginx-ip>/${ingressNodeIP}/g" |
	sed "s/<replaced-iam-server>/https:\/\/oidc-server.u4a-system.svc/g" |
	sed "s/<replace-with-k8s-oidc-proxy-url>/https:\/\/${kubeProxyNodeIP}/g" |
	sed "s/<replace-with-oidc-server-url>/https:\/\/portal.${ingressNodeIP}.nip.io\/oidc/g" |
	sed "s/<replace-with-oidc-client-id>/bff-client/g" |
	sed "s/<replace-with-oidc-client-secret>/${secret}/g" \
		>fabric-operator/values1.yaml

# baas step 2. install fabric operator
if [[ ${IGNORE_FABRIC_OPERATOR} != "YES" ]]; then
	kubectl create namespace baas-system
	helm --debug --wait --timeout=$TIMEOUT -nbaas-system install fabric -f fabric-operator/values1.yaml --wait fabric-operator
	echo "deploy fabric-operator successfully"
	kubectl get po -nbaas-system
else
	echo "According to the configuration, fabric-operator will not be installed."
fi

if [[ ${WAIT_TEKTON_INSTALL} == "YES" ]]; then
	echo "wait tekton install finish..."
	START_TIME=$(date +%s)
	while true; do
		output=$(kubectl get tektonconfig config -ojsonpath='{.status.conditions[?(@.type=="Ready")].status}' --ignore-not-found)
		if [[ ${output} == "True" ]]; then
			break
		fi
		CURRENT_TIME=$(date +%s)
		ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
		if [[ $ELAPSED_TIME -gt 600 ]]; then
			echo "wait tekton install timeout"
			kubectl get tektonconfig config -oyaml
			exit 1
		fi
		sleep 5
	done
	echo "deploy tekton successfully"
fi

# upgrade fabric
if [ ${UPGRADE_FABRIC_OPERATOR} == "YES" ]; then
	helm upgrade -n baas-system fabric -f fabric-operator/values1.yaml fabric-operator/ -i
fi

# remove fabric
if [ ${REMOVE_FABRIC_OPERATOR} == "YES" ]; then
	helm uninstall -n baas-system fabric
fi

# upgrade u4a
if [ ${UPGRADE_U4A} == "YES" ]; then
	helm upgrade -n u4a-system cluster-component -f u4a-component/charts/cluster-component/values1.yaml u4a-component/charts/cluster-component
fi
