# Tekton

[Tekton](https://tekton.dev/docs/) is a cloud-native solution for building CI/CD systems which consists of Pipelines,Tasks,PipelineRuns,TaskRuns that can help us:

- Build chaincode images and push image after build is done

## Installation

### Install tekton operator

Tekton pipeline will be automatically installed with fabric-operator.

### Post-process after tekton operator deployed

tasks/pipelines will be automatically installed by install script.


## Build Chaincode with Tekton Pipelines

### Install depencencies

#### Serivce

- Tekton-CI Serivce
- Minio Service

#### Tasks: 
- [`git-clone` task](https://github.com/tektoncd/catalog/tree/main/task/git-clone) 0.3
```
kubectl apply -f ./task/git-clone/git-clone.yaml
```

- [`minio-fetch` task](./task/minio-fetch/minio-fetch.yaml)
```
kubectl apply -f ./task/minio-fetch/minio-fetch.yaml
```

- [`docker build` task](https://github.com/tektoncd/catalog/tree/main/task/docker-build/0.1) 0.1
```
kubectl apply -f ./task/docker-build/docker-build.yaml
```

- [`kaniko` task](https://github.com/tektoncd/catalog/tree/main/task/kaniko/0.6) 0.6

```
kubectl apply -f ./task/kaniko/kaniko.yaml
```

### Install pipelines

- build with `kaniko` task (**Recommended**)
```
kubectl apply -f ./pipelines/chaincodebuild-kaniko.yaml
```

- build with `docker build` task
```
kubectl apply -f ./pipelines/chaincodebuild.yaml
```


### ChaincodeBuilds (Kaniko)

This pipeline builds chaincode source code into a container image with `srouce-fetch` and `docker build`.


#### Parameters

> Now we supports two kind of sources in pipeline [chaincodebuild](./pipelines/chaincodebuild.yaml) 

> - [Git](https://github.com/tektoncd/catalog/tree/main/task/git-clone/0.3) get build marterials(chaincode source code) from a git repo
> - [Minio](https://min.io/docs/minio/kubernetes/upstream/index.html) get build materials(chaincode source code) from Minio server(S3)


| Parameter                                   | Description                                 | Default                                                          |   Required |
| ------------------------------------------- | ------------------------------------------- | ---------------------------------------------------------------- | ---------- |
| `SOURCE`                               | The source type where chaincode code stores.Now supports minio,git  | default `minio`. |  `required` |
| `SOURCE_MINIO_BUCKET`                               | minio's bucket name  | default `bestchains`. |   `required when using minio` |
| `SOURCE_MINIO_OBJECT`                               | minio's object path  | default ""  |   `required when using minio` |
| `SOURCE_MINIO_HOST`                               | minio host/domain to fetch (fabric-minio.baas-system.svc.cluster.local)  | default `fabric-minio.baas-system.svc.cluster.local`. | `required when using minio` |
| `SOURCE_MINIO_ACCESS_KEY`                               | the accessKey used to fetch minio object  | default  |  `required when using minio` |
| `SOURCE_MINIO_SECRET_KEY`                               | the secretKey used to fetch minio object | default | `required when using minio` |
| `SOURCE_GIT_URL`                               |  The git repo url where the source code resides | default |  `required when using git` |
| `SOURCE_GIT_REFERENCE`                               | The branch, tag or SHA to checkout. | default |  `optional` |
| `SOURCE_GIT_INIT_IMAGE`                               | The init image of git-clone | default  |  `optional` |
| `APP_IMAGE`                               | The chaincode name of the image to build | default |   `required` |
| `DOCKERFILE`                               | The path of the dockerfile to execute  | default `./Dockerfile` |   `required` |
| `CONTEXT`                               | The path of the directory to use as context  | default `.`.  |   `required` |
| `INSECURE_REGISTRY`                               | Allows the user to push to an insecure registry that has been specified  | default |   `optional` |


#### Docker registry (Kaniko)

When user needs to push image to a registry which needs authorization,you should create a push secret and reference it in workspace.

1. create a docker config secret

> - update the docker config file
> - change the secret namespace to `PipelineRun Namespace`
```
 kubectl create secret generic dockerhub-secret --from-file=/root/.docker/config.json -n {Pipeline_Run_Namespace}
```

2. reference it in `PipelineRun`


reference here [Sample with source `git`](./pipelines/sample/sample_git.yaml)
```
  workspaces:
    - name: source-ws
      subPath: source
      persistentVolumeClaim:
        claimName: sample-minio-kaniko-ws-pvc
    - name: dockerconfig-ws
      secret:
        secretName: dockerhub-secret
```



#### Samples

1. Sample for Tasks:

- [`git-clone` Sample](./task/git-clone/sample/test-in-upstream.yaml)
- [`minio-fetch` Sample](./task/minio-fetch/sample/samplerun.yaml)
- [`docker-build` Sample](./task/docker-build/sample/test-in-upstream.yaml)
- [`kaniko` Sample](./task/docker-build/sample/kaniko.yaml)

2. Sample for Pipeline `chaincodebuild`

- [Sample with source `git`](./pipelines/sample/sample_git.yaml)
- [Sample with source `minio`](./pipelines/sample/sample_minio.yaml)
  - Before testing Minio, [import data into Minio](./pipelines/sample/pre_sample_minio.yaml) in advance. 
  - After testing Minio, [delete the test data from Minio](./pipelines/sample/post_sample_minio.yaml).

3. Sample for Pipeline `chaincodebuild-kaniko`
- [Sample with source `git`](./pipelines/sample/sample_git_kaniko.yaml)
- [Sample with source `minio`](./pipelines/sample/sample_minio_kaniko.yaml)
  - Before testing Minio, [import data into Minio](./pipelines/sample/pre_sample_minio.yaml) in advance.
  - After testing Minio, [delete the test data from Minio](./pipelines/sample/post_sample_minio.yaml).





