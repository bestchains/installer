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
export UPLOAD_IMAGE=NO
function save_all_images() {
	outputTar=$1
	imageListFile=$2
	if [ ! -f $imageListFile ]; then
		echo "" >$imageListFile
	fi
	echo "get all images list..."
	IMAGES=$(kubectl get po -A -o yaml | grep "image: " | awk -F ": " '{print $2}' | sort -u | grep -v "gcr.io")
	echo "compare all images list with $imageListFile"
	same=0
	echo $IMAGES | diff - $imageListFile -y -q && same=0 || same=1
	if [[ $same -eq 0 ]]; then
		echo "image list is same with cache, skip store. done.✅"
	else
		echo "try to save all cluster images to $outputTar, images list to $imageListFile..."
		echo $IMAGES >$imageListFile
		for image in ${IMAGES[@]}; do
			docker pull $image
		done
		docker save $IMAGES -o $outputTar
		UPLOAD_IMAGE=YES
		echo "save all images done.✅"
	fi
	export UPLOAD_IMAGE=$UPLOAD_IMAGE
}

function load_all_images() {
	kindName=$1
	input=$2
	if [ ! -f $input ]; then
		echo "no image found in $input, skip"
		exit 0
	fi
	echo "try to load all cluster images from $output to kind cluster $kindName..."
	kind load image-archive --name $kindName $input
	echo "load all images done.✅"
}
