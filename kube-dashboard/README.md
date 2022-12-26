Here is the steps about how to install kubernetes-dashboard using kube-oidc-proxy and oidc-gatekeeper to integrate with OIDC server for SSO.

* Prerequisite
Install u4a-component and it'll provide the account, authentication, authorization and audit funcationality built on Kubernetes.

### Install Kubernetes dashboard
1. Edit values.yaml to replace the images and the value that has prefix `<replaced-`.
```
dashboard:
  dashboardImage: hub.tenxcloud.com/addon_system/kube-dashboard:v2.7.0
  proxyImage: hub.tenxcloud.com/addon_system/keycloak-gatekeeper:latest
  metricsImage: hub.tenxcloud.com/addon_system/kube-dashboard-metrics-scraper:v1.0.8

ingress:
  class: portal-ingress
  host: kubedashboard.<replaced-ingress-nginx-ip>.nip.io

# You must check and update the value of each variable below
kubeOidcProxy:
  issuerUrl: <replaced-issuer-url> # https://portal.172.22.96.209.nip.io/oidc
  clientId: <replaced-client-id>
  clientSecret: <replaced-client-secret>
  usernameClaim: preferred_username
  groupClaim: groups
  hostConfig:
    enabled: true
    hostAliases:
    - hostnames:
      # MUST update this value
      - portal.<replaced-ingress-nginx-ip>.nip.io
      ip: <replaced-ingress-nginx-ip>
```

2. Run helm to install
```
# here we use namespace addon-system
helm install kube-dashboard -n addon-system .
```
* The pod will failed to start due to the missing of dashboard-kubeconfig configmap, and we'll create it at the next step.

3. Create the kubeconfig file for kube-dashboard to use, so it can point to the kube-oidc-proxy address, and use the correct certificate and token.
```
# copy the kubeconfig template
$ cp sample-kubeconfig kubeconfig
# edit kubeconfig file to use the correct cluster.certificate-authority-data, cluster.server, user.token

# Step 1
$ export CLUSTER_CA=$(kubectl get secret -n u4a-system oidc-proxy-cert-tls -o jsonpath='{.data.ca\.crt}')
$ use the value from $CLUSTER_CA to replace cluster.certificate-authority-data(<certificate-authority-data>) in kubeconfig file

# Step 2
$ export USER_TOKEN_NAME=$(kubectl -n addon-system get serviceaccount kubernetes-dashboard -o=jsonpath='{.secrets[0].name}')
$ export USER_TOKEN_VALUE=$(kubectl -n addon-system get secret/${USER_TOKEN_NAME} -o=go-template='{{.data.token}}' | base64 --decode)
# use the value from $USER_TOKEN_VALUE to replace user.token(<user-token>) in kubeconfig file

# Step 3 replace cluster.server(<cluster-server>) with the address of kube-oidc-proxy

# Step 4 create the configmap
$ kubectl create cm dashboard-kubeconfig --from-file=kubeconfig -n addon-system
```

4. Restart kube-dashboard
```
$ kubectl delete pod -n addon-system $(kubectl  get pod -n addon-system | grep kubernetes-dashboard | awk '{print $1}')
```

5. Access kube-dashboard using `kubedashboard.<replaced-ingress-nginx-ip>.nip.io` using browser. It should be redirected to your oidc server for login and then redirect to kube-dashboard after successful login.

### Uninstall
Uninstall using helm command below.
```
helm uninstall kube-dashboard -n addon-system
```
