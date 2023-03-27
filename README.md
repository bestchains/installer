# Installer

Here are the steps about how to install bestchains BaaS platform which include ways to install:

- a [kind](https://kind.sigs.k8s.io/) cluster
- `u4a-component` which provides identity and access management
    - [nginx ingress service](https://docs.nginx.com/nginx-ingress-controller/)
    - [cert-manager service](https://cert-manager.io/)
    - [oidc service](https://github.com/dexidp/dex)
- `baas-component` which provides blockchain management in `CloudNative` way
    - [fabric-operator](https://github.com/bestchains/fabric-operator)
    - [bc-apis](https://github.com/bestchains/bc-apis)
- more addons
    - [kuber-dashboard](https://github.com/kubernetes/dashboard)
    - [kubelogin](https://github.com/int128/kubelogin)

## Prerequisites

- [Install Docker](https://docs.docker.com/engine/install/)
- [Install kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
- [Install Helm](https://helm.sh/docs/intro/install/)
- [Install kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- Get source code
  ```shell
  $ git clone https://github.com/bestchains/installer.git;
  ```

## Quick Start

  Create a k8s cluster via kind and deploy the cluster component, u4a component and baas component.

```shell
# if  you don't have a k8s cluster, it will create a k8s cluster by kind
make kind

# it will install cluster components, u4a-components and baas components
# By default, the postgresql service is deployed under u4a-system
make e2e
```

## Manual deployment

### 1. Install u4a-component
For the 1st step, we'll install u4a-component and it'll provide the account, authentication, authorization and audit funcationality built on Kubernetes. And it has the capability to add more features following the guide later.

And then we'll deploy BaaS on top of it, and use OIDC token for SSO between u4a and baas component.


#### 1.1 Install u4a services

Enter into u4a-component folder and following the step below:

> **Note**
> This step will install a ingress nginx controller with ingressclass named 'portal-ingress' and cert-manager for certificate management.


This step will install the following services:
* cert-manager
* ingress-nginx
* Capsule for tenant management
* kube-oidc-proxy for K8S OIDC enablement
* oidc-server for OIDC and iam service
* resource-view-controller for resource aggregation view from multiple clusters

1. Create namespace `u4a-namespace`

    ```
    kubectl create ns u4a-system
    ```


2. Edit values.yaml to replace the placeholder below:
* `<replaced-ingress-nginx-ip>`, replace it with the IP address of the ingress nginx node that deployed in the previous step, this placeholder will have multiple ones
* `<replaced-oidc-proxy-node-name>`, replace it with the node name where kube-oidc-proxy will be installed
* `<replaced-k8s-ip-with-oidc-enabled>`, replace it with the IP address of node where kube-oidc-proxy will be installed, this placeholder will have multiple ones
* you should also update the image address if you're using a private registry
* edit `charts/cluster-component/values.yaml` to replace `<replaced-ingress-node-name>` with the K8S node name that will install the ingress controller, so update the value of deployedHost, and remember the IP address of this host, will use it at the next step.

    ```yaml
    ingress-nginx:
    # MUST update this value
      deployedHost: &deployedHost
        k8s-ingress-nginx-node-name
    ```


3. Determine the deployment namespace for postgresql (optional) {#pg-tcp}

    **If you need the postgresql service and need to expose the tcp service via ingress-nginx,**
    please modify `u4a-component/charts/cluster-component/values.yaml`

    ```yaml
    ingress-nginx:
      tcp:
        #<expose-port>: "<your-postgresql-namespace>/<postgresql-service-name>:<postgresql-service-port>"
        5432: "u4a-system/postgresql:5432"
    ```


4. Install u4a component using helm

    ```
    # run helm install
    $ helm install --wait u4a-component -n u4a-system .

    # wait for all pods to be ready
    $ kubectl get pod -n u4a-system
    NAME                                                          READY   STATUS    RESTARTS   AGE
    bff-server-6c9b4b97f5-gqrx6                                   1/1     Running   0          45m
    capsule-controller-manager-6cf656b98c-sjm5n                   1/1     Running   0          66m
    cert-manager-756fd78bff-wb2vh                                 1/1     Running   0          76m
    cert-manager-cainjector-64685f8d48-qg69v                      1/1     Running   0          76m
    cert-manager-webhook-5c46d68c6b-f4dkh                         1/1     Running   0          76m
    cluster-component-ingress-nginx-controller-5bd67897dd-5m9n7   1/1     Running   0          76m
    kube-oidc-proxy-5f4598c77c-fzl5q                              1/1     Running   0          65m
    oidc-server-85db495594-k6pkt                                  2/2     Running   0          65m
    resource-view-controller-76d8c79cf-smkj5                      1/1     Running   0          66m
    ```

5. At the end of the helm install, it'll prompt you with some notes like below:

    ```
    NOTES:
    1. Get the  ServiceAccount token by running these commands:

      export TOKENNAME=$(kubectl get serviceaccount/host-cluster-reader -n u4a-system -o jsonpath='{.secrets[0].name}')
      kubectl get secret $TOKENNAME -n u4a-system -o jsonpath='{.data.token}' | base64 -d
    ```

    Save the token and will use it to add the cluster later.


6. Open the host configured using ingress below:

    `https://portal.<replaced-ingress-nginx-ip>.nip.io`


    If your host isn't able to access nip.io, you should add the ip<->host mapping to your hosts file. Login with user admin/baas-admin (default one).


7. Prepare the environment
1) Create a namespace for cluster management, it should be 'cluster-system'.

    ```
    kubectl create -n cluster-system
    ```

2) Add current cluster to the portal. Navigate to '集群管理' and '添加集群'
* for API Host, use the one from `hostK8sApiWithOidc`
* for API Token, use the one you saved from step 3.

Now, you should have a cluster and a 'system-tenant' and tenant management.

### 2. Install baas-component

#### 2.1 Install Fabric-Operator and bc-api using Helm

1. Create namespace

    If you want to install operator under the namespace `baas-system`, and this namespace does not exist, you need to create this namespace.

    ```shell
    kubectl create ns baas-system
    ```

2. Install Fabric-Operator And bc-apis

    Before installation, the content to be replaced needs to be updated.
    - \<replaced-ingress-nginx-ip\>
    - \<replaced-iam-server\>
    - \<replace-with-k8s-oidc-proxy-url\>
    - \<replace-with-oidc-server-url\>
    - \<replace-with-oidc-client-id\>
    - \<replace-with-oidc-client-secret\>

    ```shell
    $ cd installer;
    $ helm -nbaas-system install fabric fabric-operator;
    ```
    For more configuration parameters, please refer to the following document: [install-fabric-operator](./fabric-operator/README.md)

3. Verify pods are running properly.

    ```shell
    $ kubectl get po -nbaas-system
    NAME                                          READY   STATUS    RESTARTS   AGE
    bff-apis-5b857f6577-c6pjz                     1/1     Running   0          55s
    controller-manager-5d6449b864-ckf25           1/1     Running   0          55s
    ```

4. Clean up the deployment environment
    ```shell
    helm -nbaas-system uninstall fabric;

    kubectl delete ns baas-system;
    ```


### 3.  Install bc-explorer

#### 3.1 Separate installation of postgresql

You can install postgresql by the command:

```bash
helm --wait --timeout=300 -n baas-system install postgresql explorer/explorer/charts/postgresql
```
It will add new user `bestchains` with password `Passw0rd!`, Also create database `bestchains`.


#### 3.2 Install Explorer with postgresql

If you have installed `postgresql`, Please edit `explorer/explorer/Charts.yaml`.

```yaml
dependencies:
  - name: postgresql
    condition: postgresql.disabled
```
The bc-explorer needs to be exposed via ingress, so make sure the `<replaced-ingress-nginx-ip>` is set correctly.

And the postgresql access address has been set correctly. Postgresql is accessed by default via tcp forwarding from ingress-nginx, if you have another address, please replace `pdAddr`.

Install `bc-explorer` by the command:

```bash
helm --wait --timeout=300 -nbaas-system install bc-explorer explorer/explorer
```

### 4. Add more components
1. Install kube-dashboard following [this doc](./kube-dashboard/) to integrate with u4a.

    Refer to [kubernetes dashboard ](https://github.com/kubernetes/dashboard) for details.

2. Install kubelogin following [this doc](./kubelogin/) to integrate with u4a

    Refer to [kubelogin](https://github.com/int128/kubelogin) for details.
