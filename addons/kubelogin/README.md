Here is the steps about how to install kubelogin to integrate with OIDC server for kubectl tool, so you can do authentication with Kubernetes.

* Prerequisite
Install u4a-component and it'll provide the account, authentication, authorization and audit funcationality built on Kubernetes.

### Install kubelogin
Get the binary here [download](https://github.com/int128/kubelogin/releases) and download the one matching your OS.

Then you need to put the kubelogin binary on your path under the name kubectl-oidc_login so that the kubectl plugin mechanism can find it when you invoke kubectl oidc-login.

### Prepare kubeconfig file
1. Backup your original config file under ~/.kube/config and create a new one.
```
$ cd ~/.kube
$ cp config config_backup
$ kubectl config set-credentials oidc \
	  --exec-api-version=client.authentication.k8s.io/v1beta1 \
	  --exec-command=kubectl \
	  --exec-arg=oidc-login \
	  --exec-arg=get-token \
	  --exec-arg=--oidc-extra-scope=email \
	  --exec-arg=--oidc-extra-scope=profile \
	  --exec-arg=--oidc-issuer-url=https://portal.172.22.96.209.nip.io/oidc \
	  --exec-arg=--oidc-client-id=bff-client \
	  --exec-arg=--oidc-client-secret=61324af0-1234-4f61-b110-ef57013267d6 \
	  --exec-arg=--insecure-skip-tls-verify
```

2. Point the cluster to kube-oidc-server or k8s-apiserver if oidc is enabled.
```
- cluster:
    certificate-authority-data: ....
    server: https://172.22.96.133 # Update this value
  name: cluster-name
```

3. Add `http://localhost:8000` as a valid redirect URL of your OIDC server, so it can redirect to local server after successful login.

4. Switch current context to oidc
```
$ kubectl config set-context --current --user=oidc
```
Run `kubectl get nodes`, kubectl executes kubelogin before calling the Kubernetes APIs. Kubelogin automatically opens the browser, and you can log in to the provider.

After successful login, you'll get a `Authenticated` response.

5. If you get `Unable to connect to the server: x509: certificate signed by unknown authority` error after `kubectl get nodes`. Remove certificate-authority-data, and add insecure-skip-tls-verify as true.
```
- cluster:
    # certificate-authority-data: ....
    server: https://172.22.96.133
    insecure-skip-tls-verify: true # Add it here
  name: cluster-name
```
You can also use a valid certificate data, for example:
```
export CLUSTER_CA=$(kubectl get secret -n u4a-system oidc-proxy-cert-tls -o jsonpath='{.data.ca\.crt}')
# Use the data from CLUSTER_CA and set to certificate-authority-data
```
Then you can run any kubectl using the logged in user, Kubernetes RBAC and audit will take effect for the user.

### Get id token from cached file
The id_token will be cached in ~/.kube/cache/oidc-login/<cahced-file>, you can use `cat` to get the content and token from this file. For example:
```
{"id_token":"eyJhbGciOiJSUzI1NiIsImtpZCI6IjBkMzEyM2U1MWIxN2IzZTNlNDYzNjgxZTMzZTFkOTNkM2RiY2IwZDkifQ.eyJpc3MiOiJodHRwczovL3BvcnRhbC4xNzIuMjIuOTYuMjA5Lm5pcC5pby9vaWRjIiwic3ViIjoiQ2dWaFpHMXBiaElHYXpoelkzSmsiLCJhdWQiOiJiZmYtY2xpZW50IiwiZXhwIjoxNjc0MzU3OTU0LCJpYXQiOjE2NzQyNzE1NTQsIm5vbmNlIjoiVHhJVlE4VlFINW9PTGtLeGV1ekk3VWp3VVU0WUYyOEQ1N18xLWVpVWEtVSIsImF0X2hhc2giOiJOamZKZWJ1Ry1uUlVlWDJNY2dfZzVRIiwiY19oYXNoIjoiQWVQdUtsTmN5RjgyTy1xWFFqUzEwdyIsImVtYWlsIjoiYWRtaW5AdGVueGNsb3VkLmNvbSIsImVtYWlsX3ZlcmlmaWVkIjp0cnVlLCJuYW1lIjoiYWRtaW4iLCJwcmVmZXJyZWRfdXNlcm5hbWUiOiJhZG1pbiIsInBob25lIjoiIiwidXNlcmlkIjoiYWRtaW4ifQ.YtmRZbS7-B0s0vVh9myH1FYcWuKoKNNYkPZQ5asbrQE2n8eC7w74n8D7pvM6v44kvBnp27hNOeo06EK4leNR2Inb2UJtd2QBS1L9i4A3V_vm06o4DkvqfyNcbD7-hL6ES0XkzIKimG3WMMJIznvuA71W_88t77U7jC7wvtKbT7k1KZWgOV6VappWlz7uecuBSQahoCku5AO-s25H1O-FbodOYtL8-ju0sqiHrgmbNaV-f6Wuvvk9XkquAe_dztqWCJ0axfUW7u4J-M947mlR1JlWwbhm-nQXgvugyMVh3FjFOjwi7jR3BA3Me-iuS_XPNSWx-DB0dfsCfErCJ9DvBA"}
```

### Get id token using username/password
1. Enable passwordConnector in the oidc-server configuration
```
# kubectl edit cm oidc-server -n u4a-system
    oauth2:
      # Enable this one
      passwordConnector: k8scrd
      skipApprovalScreen: true
```
2. Get id token using kubelogin or curl

* kubelogin
```
kubelogin get-token --oidc-issuer-url=https://portal.172.22.96.209.nip.io/oidc --oidc-client-id=bff-client --oidc-client-secret=61324af0-1234-4f61-b110-ef57013267d6 --insecure-skip-tls-verify --grant-type=password --username=admin --password=admiN\$123

# here is the response, get the token from the json
{"kind":"ExecCredential","apiVersion":"client.authentication.k8s.io/v1beta1","spec":{"interactive":false},"status":{"expirationTimestamp":"2023-02-11T04:37:32Z","token":"eyJhbGciOiJSUzI1NiIsImtpZCI6ImY2ZjFjMjFkNzFhOGEyYmU3ZTg2YjQyYWIwOTYwY2MxNzU3NjdiM2MifQ.eyJpc3MiOiJodHRwczovL3BvcnRhbC4xNzIuMjIuOTYuMjA5Lm5pcC5pby9vaWRjIiwic3ViIjoiQ2dWaFpHMXBiaElHYXpoelkzSmsiLCJhdWQiOiJiZmYtY2xpZW50IiwiZXhwIjoxNjc2MDkwMjUyLCJpYXQiOjE2NzYwMDM4NTIsImF0X2hhc2giOiJyLWtsUnBQcEd3U0I5TFQyelVQSWtRIiwicGhvbmUiOiIifQ.tFOmGN1w79I_s5pWZZK4zEEHwCyuJRwkNtacmxVcCY-Jms-JOzXUJTxnNm8XzIBC3cZqt5U6oNXMuk68MHq0v3g2tQKJeAwV1aojJrIIp5QHefXMUjl_hTaFe1tRgwsvZqBWhExLi1yaTSUfjmP_SZEb23A0R_AWvc7ClO7sbuKQlkPG_gi2TPCBOeTx0UmlQ14w6U3dIJhR57hXfttdSr2nRqKma8bp_jAiUiWaKLSWSyc3tQsxWl7LeAAbRM3URx-3winVIEPEpUgwIBXnrr-ba9BZwZoD5NGytOGw4xA80eGDmmMIG8U2QarJKsZErpzS7EWbiPBLgS2_Wg1eBA"}}
```
* curl
```
curl -k -XPOST https://portal.172.22.96.209.nip.io/oidc/token -H "Authorization: Basic <base64 of oidc-client-id:oidc-client-secret>" -H "Content-Type: application/x-www-form-urlencoded"  --data 'grant_type=password&password=password&scope=openid&username=username'

# here is the response, and get id_token from the json
{"access_token":"eyJhbGciOiJSUzI1NiIsImtpZCI6ImY2ZjFjMjFkNzFhOGEyYmU3ZTg2YjQyYWIwOTYwY2MxNzU3NjdiM2MifQ.eyJpc3MiOiJodHRwczovL3BvcnRhbC4xNzIuMjIuOTYuMjA5Lm5pcC5pby9vaWRjIiwic3ViIjoiQ2dWaFpHMXBiaElHYXpoelkzSmsiLCJhdWQiOiJiZmYtY2xpZW50IiwiZXhwIjoxNjc2MDkyOTk0LCJpYXQiOjE2NzYwMDY1OTQsImF0X2hhc2giOiJtM2xsQWprUXdlQnhJbUJlQkgxRG1RIiwicGhvbmUiOiIifQ.iel5l_mzlVf2LjbMqzqXb3sqb7L195a-fY4Aaon2_CVn1lBMzOf2qDYbtVF3KhGHxNlaKRxig63uCDfyts84BMD5-Uaz_x4_mq5QaMVYVYEUw9NWsLP-jQ0bTSZE7MZKlxz_a3AGW_fXwW0Y02dqemugBfC3IagBhroYI2PSTKcNCCQz2aao-ZSQ5-rysKSyo0VPDtcY_K8ikpDChLM9GhUKzbdIvctO6mGBOOKHRkiCAbRegOCFhJ6-0O4k6b-m3rXyJkQAIBfesOPIAFxhQQhg3y9wDEVxbBTZ99fwfvfIuSxN_vsITKCsqpRr7t-30jqReIKsYktyzZ15jiJhKg","token_type":"bearer","expires_in":86399,"id_token":"eyJhbGciOiJSUzI1NiIsImtpZCI6ImY2ZjFjMjFkNzFhOGEyYmU3ZTg2YjQyYWIwOTYwY2MxNzU3NjdiM2MifQ.eyJpc3MiOiJodHRwczovL3BvcnRhbC4xNzIuMjIuOTYuMjA5Lm5pcC5pby9vaWRjIiwic3ViIjoiQ2dWaFpHMXBiaElHYXpoelkzSmsiLCJhdWQiOiJiZmYtY2xpZW50IiwiZXhwIjoxNjc2MDkyOTk0LCJpYXQiOjE2NzYwMDY1OTQsImF0X2hhc2giOiJRT3NNWGdSeDRYaUJJTVZwSElXeUlRIiwicGhvbmUiOiIifQ.ZDU7AouftfpLAs2SDE3Kb86ggVyDEwrgA3jtUxitKUQwKqosjWiaEEGc3w824FAC3eDZhFr1w5uXT6R30O2s0DPzPb0nesDN8wa2ZscU9ESjZrKAAgpgM7uE1vU41mi7GfdZEUHabx83XFvu69KvmA9OKnqaSdyi3-aPYHyBP5GfNYoQ-mteCBsAbRF8l6fe1VREIYV3sQrBC8b9s1Ony4F8YFWgFE4G_1gxV-0qz8IxgzhLGUgehuwsHTUjMLvyGgTiFrFvrPsftEuEGtOQbKswngWQGlYWSsUIWb79Fdk_-wD08fyM9YUGJyb0Bg_HO2M95CFsSASB4HDO4QHOXw"}
```

### Logout
You can remove the local cache files under `~/.kube/cache/oidc-login/<cached-file>` to logout current user.
