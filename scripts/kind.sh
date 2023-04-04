#!/usr/bin/env bash
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/..
echo $ROOT

IGNORE_FIXED_IMAGE_LOAD=${IGNORE_FIXED_IMAGE_LOAD:-"NO"}

function kind_up_cluster {
	# when update kind version, please change this file and github action file.
	# https://github.com/kubernetes-sigs/kind/releases
	case $K8S_VERSION in
	v1.18 | v1.18.20)
		kind_image="kindest/node:v1.18.20@sha256:61c9e1698c1cb19c3b1d8151a9135b379657aee23c59bde4a8d87923fcb43a91"
		;;
	v1.19 | v1.19.16)
		kind_image="kindest/node:v1.19.16@sha256:707469aac7e6805e52c3bde2a8a8050ce2b15decff60db6c5077ba9975d28b98"
		;;
	v1.20 | v1.20.15)
		kind_image="kindest/node:v1.20.15@sha256:d67de8f84143adebe80a07672f370365ec7d23f93dc86866f0e29fa29ce026fe"
		;;
	v1.21 | v1.21.14)
		kind_image="kindest/node:v1.21.14@sha256:f9b4d3d1112f24a7254d2ee296f177f628f9b4c1b32f0006567af11b91c1f301"
		;;
	v1.22 | v1.22.13)
		kind_image="kindest/node:v1.22.13@sha256:4904eda4d6e64b402169797805b8ec01f50133960ad6c19af45173a27eadf959"
		;;
	v1.23 | v1.23.10)
		kind_image="kindest/node:v1.23.10@sha256:f047448af6a656fae7bc909e2fab360c18c487ef3edc93f06d78cdfd864b2d12"
		;;
	v1.24 | v1.24.4)
		kind_image="kindest/node:v1.24.4@sha256:adfaebada924a26c2c9308edd53c6e33b3d4e453782c0063dc0028bdebaddf98"
		;;
	v1.25 | v1.25.0)
		kind_image="kindest/node:v1.25.0@sha256:428aaa17ec82ccde0131cb2d1ca6547d13cf5fdabcc0bbecf749baa935387cbf"
		;;
	*)
		echo $K8S_VERSION "is not support"
		exit 1
		;;
	esac
	echo "kind to create cluster"
	kind create cluster --config=$ROOT/scripts/kind-conf.yaml --image $kind_image
	echo "kind cluster created done."
}

function pre_load_image() {
	pre_load_images=(
		hyperledgerk8s/ubi-minimal:latest
		hyperledgerk8s/fabric-ca:iam-20230131
		hyperledgerk8s/fabric-peer:2.4.7
		hyperledgerk8s/fabric-peer:2.4.7
		hyperledgerk8s/couchdb:3.2.2
		hyperledgerk8s/fabric-orderer:2.4.7
		hyperledgerk8s/fabric-console:latest
		hyperledgerk8s/grpc-web:latest
		hyperledgerk8s/tektoncd-operator:v0.64.0
		hyperledgerk8s/tekton-operator-webhook:v0.64.0
		hyperledgerk8s/tekton-pipeline-controller:v0.42.0
		hyperledgerk8s/tekton-pipeline-webhook:v0.42.0
		hyperledgerk8s/tekton-pipeline-resolvers:v0.42.0
		hyperledgerk8s/tekton-triggers-controller:v0.22.0
		hyperledgerk8s/tekton-triggers-interceptors:v0.22.0
		hyperledgerk8s/tekton-triggers-webhook:v0.22.0
		hyperledgerk8s/tekton-dashboard:v0.31.0
		hyperledgerk8s/tekton-pipeline-args-entrypoint:v0.42.0
		hyperledgerk8s/tekton-pipeline-args-git-init:v0.42.0
		hyperledgerk8s/tekton-pipeline-args-kubeconfigwriter:v0.42.0
		hyperledgerk8s/tekton-pipeline-args-nop:v0.42.0
		hyperledgerk8s/tekton-pipeline-args-imagedigestexporter:v0.42.0
		hyperledgerk8s/tekton-pipeline-args-pullrequest-init:v0.42.0
		hyperledgerk8s/tekton-pipeline-args-workingdirinit:v0.42.0
		hyperledgerk8s/tekton-pipeline-args-cloud-sdk:27b2c2
		hyperledgerk8s/tekton-pipeline-args-busybox:19f022
		hyperledgerk8s/tekton-pipeline-args-powershell:nanoserver-b6d5ff
		hyperledgerk8s/minio-minio:RELEASE.2023-02-10T18-48-39Z
		hyperledgerk8s/minio-mc:RELEASE.2023-01-28T20-29-38Z
		hyperledgerk8s/registry:2
		hyperledgerk8s/docker:dind
		hyperledgerk8s/docker:stable
		hyperledgerk8s/kaniko-executor:v1.9.1
		hyperledgerk8s/bash:5.1.4
		hyperledgerk8s/ubuntu:22.04
		hyperledgerk8s/tekton-job-pruner-tkn:025de221fb05
	)
	for image in ${pre_load_images[*]}; do
		docker pull ${image}
		kind load docker-image ${image}
	done
}

export K8S_VERSION=v1.24
kind_up_cluster
if [[ ${IGNORE_FIXED_IMAGE_LOAD} != "YES" ]]; then
	pre_load_image
else
	echo "According to the configuration, pre_load_image will not running."
fi
