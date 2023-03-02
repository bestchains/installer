# Baas Helm Chart

## Installation

Quick start to deploy Baas using Helm.

### Prerequisites

- [Helm](https://helm.sh/docs/intro/quickstart/#install-helm)

#### Install chart using Helm v3.0+

1. Get source code

        ```shell
        $ git clone https://github.com/bestchains/installer.git;
        $ cd installer;
        ```

2. Some variables that must be modified


- `<replaced-ingress-nginx-ip>` needs to be replaced with the ip address of ingress
- `<replaced-iam-server>` needs to be replaced with iam server address. example: https://oidc-server.system.svc
- `<replace-with-k8s-oidc-proxy-url>` 
- `<replace-with-oidc-server-url>` 
- `<replace-with-oidc-client-id>`
- `<replace-with-oidc-client-secret>`


    ```shell
    # If namespace does not exist.
    $ kubectl create ns baas-system;
    $ helm -nbaas-system install fabric fabric-operator;
    ```

#### Verify pods are running properly.

```shell
$ kubectl get po -nbaas-system
NAME                                          READY   STATUS    RESTARTS   AGE
bff-apis-5b857f6577-c6pjz                     1/1     Running   0          55s
controller-manager-5d6449b864-ckf25           1/1     Running   0          55s
```

### Configuration

The following table lists the configurable parameters of fabric-operator chart and their default values.

| Parameter                                   | Description                                 | Default                                                          |
| ------------------------------------------- | ------------------------------------------- | ---------------------------------------------------------------- |
| `namespace`                               | which namespace the operator will be deployed.   | default `baas-system`. |
| `ingressDomain`                           | ingress domain.    | default `empty`, **you must set it**.       |
| `ingressClassName`                        | default ingress class name in fabric-operator and bc-apis  | default `portal-ingress` which installed by `installer`,  **you must set it**    |
| `storageClassName`                        | default storage class name in fabric-operator and bc-apis   | default `empty`      |
| `minio.host`                              | The minio host   | default `minio.bestchains-addons.svc.cluster.local`   |
| `minio.accessKey`                         | The access key for accessing Minio  | default   |
| `minio.secretKey`                         | The secret key for accessing Minio   | default   |
| `tekton.namespace`                        | The namespace where bestchains' taks/pipeline/taskrun/pipelinerun will be deployed   | default `bestchains-pipelinerun`   |
| `tekton.dockerConfigSecret`               |  The docker config secret which will be used to push/pull built images  | default `dockerhub-secret`   |
| `operator.watchNamespace`                 | The namespace under which the CR is created can trigger the operator's logic.   | default `empty`, means all namespace. |
| `operator.clusterType`                    | K8S, or OPENSHIFT. | default `K8S`.                |
| `operator.iamServer`                      | iam provider address.                            | default `emtpy`, **you must set it**.   |
| `operator.image`                          | The image that the operator deployment will use. | default `hyperledgerk8s/fabric-operator:latest`   |
| `operator.imagePullPolicy`                | image pull policy.          | default `IfNotPresent`. Other optional values for reference [image pull policy](https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy)  |
| `operator.clusterRoleName`                |  cluster role name. | The clusterrole contains the permissions required by the operator's serviceaccount. default `manager-role` |
| `operator.clusterRoleBindingName`         | cluster role binding   | default `operator` |
| `operator.resources`                      | request resource.  | default request cpu is `100m`, default request memory is `200Mi` |
| `operator.readinessProbe`                 | readiness probe        |                |
| `operator.tolerations`                    | Pod tolerated stains   | Tolerate all stains by default    |
| `operator.affinity`                       | How pods are scheduled |                                   |
| `leaderElection.roleName`                 | The name of the role that contains the permissions needed for operator elections | default `leader-election-role` |
| `leaderElection.roleNameBinding`          | role binding   | default `leader-election-rolebinding`  |
| `authProxy.authProxyServiceName`          | service name   | default `controller-manager-metrics-service` |
| `authProxy.proxyClusterRoleName`          | cluster role name                  | default `proxy-role`           |
| `authProxy.proxyClusterRoleBindingName`   | cluster rolebinding name           | default `proxy-rolebinding`    |
| `authProxy.metricReaderClusterRoleName`   | metrics reader cluster role name   | default `metrics-reader`        |
| `bcapi.name`                              | Composited APIs for fabric resource APIs   | default `bff-apis`        |
| `bcapi.env.k8sOIDCProxyURL`               | oidc proxy url   | it can be emtpty if you don't need oidc-proxy.        |
| `bcapi.env.OIDCServerURL`                 | oidc server  | must be completed       |
| `bcapi.env.OIDCServerClientID`            | oidc client id   | must be completed       |
| `bcapi.env.OIDCServerClientSecret`        | oidc client secret   | must be completed       |
| `bcapi.image`                             | image used by the bff service |  hyperledgerk8s/bc-apis:v0.1.0-20230118     |
| `bcapi.imagePullPolicy`                   | the policy of pulling image  | `IfNotPresent` |
| `bcapi.hostAliases`                       | add entry to Pod's /etc/hosts  | can be empty, format reference [adding-additional-entries-with-hostaliases](https://kubernetes.io/docs/tasks/network/customize-hosts-file-for-pods/#adding-additional-entries-with-hostaliases)    |
| `bcapi.ingressName`                       | name of the ingress of the bff service| `bc-apis-ingress` |