# Tekton

[Tekton](https://tekton.dev/docs/) is a cloud-native solution for building CI/CD systems which consists of Pipelines,Tasks,PipelineRuns,TaskRuns that can help us:

- Build chaincode images and push image after build is done

## Installation

### Install tekton operator
Todo...

### Post-process after tekton operator deployed

Todo: Install tasks/pipelines for ChaincodeBuild


## Build Chaincode with Tekton Pipelines

### Install depencencies

#### Serivce

- Tekton-CI Serivce
- Minio Service

#### Tasks: 
- [`git-clone` task](https://github.com/tektoncd/catalog/tree/main/task/git-clone) 0.3
```
kubectl apply -f https://api.hub.tekton.dev/v1/resource/tekton/task/git-clone/0.3/raw
```

- [`minio-fetch` task](./task/minio-fetch/minio-fetch.yaml)
```
kubectl apply -f ./task/minio-fetch/minio-fetch.yaml
```

- [`docker build` task](https://github.com/tektoncd/catalog/tree/main/task/docker-build/0.1)
```
kubectl apply -f https://api.hub.tekton.dev/v1/resource/tekton/task/docker-build/0.1/raw
```

- [`kaniko` task](https://github.com/tektoncd/catalog/tree/main/task/kaniko/0.6)

```
kubectl apply -f https://api.hub.tekton.dev/v1/resource/tekton/task/kaniko/0.6/raw 
```

### Install pipelines

- build with `docker build` task
```
kubectl apply -f ./pipelines/chaincodebuild.yaml
```

- build with `kaniko` task (**Not supported yet**)
```
kubectl apply -f ./pipelines/chaincodebuild-kaniko.yaml
```

### ChaincodeBuilds

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
| `SOURCE_MINIO_HOST`                               | minio host/domain to fetch (minio.tekton-pipelines-addons.svc.cluster.local)  | default `minio.tekton-pipelines-addons.svc.cluster.local`. | `required when using minio` |
| `SOURCE_MINIO_ACCESS_KEY`                               | the accessKey used to fetch minio object  | default  |  `required when using minio` |
| `SOURCE_MINIO_SECRET_KEY`                               | the secretKey used to fetch minio object | default | `required when using minio` |
| `SOURCE_GIT_URL`                               |  The git repo url where the source code resides | default |  `required when using git` |
| `SOURCE_GIT_REFERENCE`                               | The branch, tag or SHA to checkout. | default |  `optional` |
| `SOURCE_GIT_INIT_IMAGE`                               | The init image of git-clone | default  |  `optional` |
| `APP_IMAGE`                               | The chaincode name of the image to build | default |   `required` |
| `DOCKERFILE`                               | The path of the dockerfile to execute  | default `./Dockerfile` |   `required` |
| `CONTEXT`                               | The path of the directory to use as context  | default `.`.  |   `required` |
| `INSECURE_REGISTRY`                               | Allows the user to push to an insecure registry that has been specified  | default |   `optional` |
| `BUILD_ARGS`                               | Extra parameters passed for the build command when building images.  | default |   `optional` |
| `PUSH_ARGS`                               | Extra parameters passed for the push command when pushing images. | default |   `optional` |

#### Samples

1. Sample for Task `minio-fetch`

- [Sample](./task/minio-fetch/sample/samplerun.yaml)

2. Sample for Pipeline `chaincodebuild`

- [Sample with source `git`](./pipelines/sample/sample_git.yaml)
- [Sample with source `minio`](./pipelines/sample/sample_minio.yaml)

3. Sample for Pipeline `chaincodebuild-kaniko` (Not supported yet)





