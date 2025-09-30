# Unit 13 Workshop

## Scenario

Before starting the exercise you'll need to [setup the scenario on Pluralsight following the instructions here](./setup/workshop_scenario_setup.md).


## Prerequisites

Assuming you're **NOT** using GitHub Codespaces or a Dev Container,  before we can spin up a cluster on Azure Kubernetes Service (AKS), we'll first need to install some tools:

### Docker

Follow one of these tutorials to install Docker:

1. [Docker Desktop (Windows)](https://docs.docker.com/docker-for-windows/install/)
2. [Docker Desktop (Mac)](https://docs.docker.com/docker-for-mac/install/)
3. [Docker Engine (Linux)](https://docs.docker.com/engine/install/#server)

Once it's installed, start it up and leave it running in the background.

### The Azure CLI

1. Follow [this tutorial](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) to install the Azure CLI (`az`).
2. Authenticate with your Azure account: open a terminal and run `az login`.

> You can find your subscription ID by logging in to the [Azure Portal](https://portal.azure.com), navigating to the Softwire Academy directory, and opening the Subscriptions service.

### The Kubernetes CLI

Follow [this tutorial](https://kubernetes.io/docs/tasks/tools/) to install the Kubernetes CLI (`kubectl`).

### The Helm CLI

Follow [this tutorial](https://helm.sh/docs/intro/install/) to install the Helm CLI (`helm`).

> If you are on Windows then the `./get_helm.sh` script won't work. So use Chocolatey if you have it. If you don't have Chocolatey, then download the [executable](https://github.com/helm/helm/releases), unzip it somewhere and add that folder to your PATH.

## Installing a Service

In this section we'll create a cluster and use it to run an Nginx server behind a load balancer.

### Spinning up a cluster

Now that we have a resource group, we can create a Kubernetes cluster inside it.
We'll just create a single Node for now; we'll scale up the cluster later in the workshop.

```bash
az aks create --resource-group myResourceGroup --name myAKSCluster --node-count 1 --node-vm-size standard_b2s --generate-ssh-keys
```

> The `az aks create` command can take around 10 minutes to complete.
> You can view the new cluster in the Azure Portal on the `Overview` page of your resource group.
> If you see a warning banner at the top of the page about permissions, don't worry. It is warning you that you don't have permission to view the resources created by the cluster, but that's not an issue as you won't need to view or manage those directly.

Before we can manage resources on the cluster, we need to get some access credentials.
This command stores the necessary credentials in your `~/.kube/config` folder.
`kubectl` will use these credentials when connecting to the Kubernetes API.

```bash
az aks get-credentials --resource-group myResourceGroup --name myAKSCluster
```

Let's use `kubectl` to check if our Node is up and running.

```bash
kubectl get nodes
```

You should see a Node that's `Ready`, e.g.:

```text
NAME                     STATUS   ROLES   AGE   VERSION
aks-default-28776938-0   Ready    agent   5m    v1.19.11
```

> In AKS, Nodes with the same configuration are grouped together into Node pools.
> You can view your Node pool in the Azure Portal on the `Node pools` page of your cluster.
> This Node pool should have a `Node count` of 1, matching the `--node-count` that we specified when creating the cluster.

At this point in the workshop, we've set up our tools, created a resource group, and spun a cluster that contains a single Node.

### Creating some Pods

Now that we have a cluster, let's try deploying an application.
This application will turn our cluster into a basic Nginx server.

Lets start by deploying a Deployment to our cluster.
This Deployment will manage two Pods, each based on the `nginx` container image.
We can create a `unit-13-deployment-2-replicas.yaml` file to define our Deployment.

```yaml
# unit-13-deployment-2-replicas.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: unit-13-deployment
spec:
  selector:
    matchLabels:
      app: unit-13-pod
  replicas: 2
  template:
    metadata:
      labels:
        app: unit-13-pod
    spec:
      containers:
        - name: container-name
          image: nginx
          ports:
            - containerPort: 80
```

```bash
kubectl apply -f unit-13-deployment-2-replicas.yaml
```

Now we can watch Pods be created during the deployment.

```bash
kubectl get pods --watch
```

> You can exit this command by pressing `CTRL+C`.
>
> You should now be able to see a `unit-13` Deployment with two available Pods on the `Workloads` page of your cluster.
> If you click through into the `unit-13` Deployment's page, then you should see a single ReplicaSet containing two Pods.

### Deploying a Service using `kubectl`

At this point, we have two Pods running on our Node, but they aren't accessible to the outside world.
Let's create a LoadBalancer Service that exposes a single external IP address for the Pods.

```yaml
# service.yaml
kind: Service
apiVersion: v1
metadata:
  name: unit-13-service
spec:
  type: LoadBalancer
  selector:
    app: unit-13-pod
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

```bash
kubectl apply -f service.yaml
```

The LoadBalancer Service type will create an externally accessible endpoint, but this can take a little while to complete.
Let's watch the deployment as it progresses.

```bash
kubectl get service unit-13-service --watch
```

Initially, the `EXTERNAL-IP` will be `<pending>`, but after a short while we should get an external IP address.

```text
NAME               TYPE           CLUSTER-IP   EXTERNAL-IP   PORT(S)          AGE
unit-13-service  LoadBalancer   10.0.37.27   <pending>     80:30572/TCP     6s
```

> You should now see a `unit-13` Service on the `Services and ingresses` page of your cluster.
> The Service's `External IP` should match the `EXTERNAL-IP` retrieved above.

We now have a load balancer that will distribute network traffic between our Pods.
Opening the external IP address in a browser should take you to a basic Nginx homepage.

### Changing configuration

If our Service was experiencing heavy load, we might want to increase the number of Pods.
We can manually adjust that by changing the number of replicas in our Deployment definition, then re-deploying it.

```yaml
# unit-13-deployment-3-replicas.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: unit-13-deployment
spec:
  selector:
    matchLabels:
      app: unit-13-pod
  replicas: 3
  template:
    metadata:
      labels:
        app: unit-13-pod
    spec:
      containers:
        - name: container-name
          image: nginx
          ports:
            - containerPort: 80
```

```bash
kubectl apply -f unit-13-deployment-3-replicas.yaml
```

Kubernetes will use the `app: unit-13-pod` label to compare what's currently deployed to the cluster (two Pods), with what we want to be deployed (three Pods).
It will then create an additional Pod.

We can check that we now have three Pods.

```bash
kubectl get pods --watch
```

> The `unit-13` Deployment on the `Workloads` page of your cluster should now have three available Pods.

### Removing Deployments and Services

Before we move on to Helm, let's get back to a clean slate by deleting our Deployment and Service.

```bash
kubectl delete deployment unit-13-deployment
kubectl delete service unit-13-service
```

We now just have a cluster with a single Node, without any Pods or load balancers.

## Deploying a Service with Helm

So far, we've manually deployed an application using manifests.
We'll now improve this process using Helm.

In this workshop we'll use a local Helm chart.
However, when creating professional applications, you might use a central chart library.

### Deploying a chart

Rather than running `kubectl apply` on each manifest, we can use Helm to deploy them all together:

```bash
helm install my-chart ./workshop-helm-chart
```

> The install command takes a couple of parameters: the first is the name of the deployment, and the second is the location of the chart.

We can then view the status of the deployment:

```bash
helm status my-chart
```

Once the deployment has finished, there should be a new `unit-13-helm` Service.
Navigating to this Service's IP address should show the Nginx homepage seen earlier.

### Updating a Service

So far, we've only seen Helm doing what `kubectl` can do, so why is it worth the effort?

Let's say we want to apply some specific additional configuration, such as the number of instances required to support the application's load.

Looking in the `values.yaml` file, we can see we've already got a `replicas` field.
We can optionally override that when deploying:

```bash
helm upgrade --set replicas=4 my-chart ./workshop-helm-chart
```

And then we can watch the new Pod being created:

```bash
kubectl get pods --watch
```

> It is good practice to update the versions in Chart.yaml each time we make changes to the Helm chart or application, but this is not required.

## Working with container registries

We'll now have a look at using images from container registries, to deploy a copy of the "image processing" application, similar to that from the logging workshop from Unit 10. You will build and publish an image, and then use Helm to deploy it to your cluster.

### Creating a container registry

We'll start by using the Azure CLI to create a container registry, which will be hosted by Azure.

```bash
az acr create --resource-group myResourceGroup --name myregistryname --sku Basic
```

> The `myregistryname` that you pick must be unique within Azure (and should be lowercase).
>
> In the Azure Portal, you should now see a container registry on the `Overview` page of your resource group.

This container registry is _private_, and will require credentials to access.

The output of this command should include a `loginServer`.
We'll need this information when pushing to the registry, so make a note of it.

> You can find more information about using container registries in the [Azure documentation](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-get-started-azure-cli).

### Building a container image

Next, we'll build an image that could be added to the registry.

We've included an adapted version of the Unit 10 order processing application in this repository.
Instead of processing orders it now processes images, this is CPU intensive so it will be easier to trigger autoscaling later in the exercise.

1. Run `cd order-processing-app` to navigate to the folder.
2. Run `docker build --target production --tag our-image-name:v1 .` to build an image of the application.
3. Run `cd ..` to move back out to the parent folder.

> If you run `docker image ls` then you should see the newly created image.

### Pushing a container image to a registry

Now that we have an image, we can push it to the registry.

Let's log in to the registry:

```bash
az acr login --name myregistryname
```

And then tag the image specifically for the registry:

```bash
docker tag our-image-name:v1 <login-server>/our-image-name:v1
```

And finally, push the image to the registry:

```bash
docker push <login-server>/our-image-name:v1
```

> Replace `<loginServer>` with the `loginServer` noted down when creating the registry.
>
> You should now be able to see this image in the Azure Portal on the `Repositories` page of your container registry.

### Using an image from a registry

Our Helm chart currently hardcodes the image in `deployment.yaml`.
Let's make it easier to change dynamically by using a variable instead.

First, add a variable in `values.yaml`, referencing our newly created image, e.g. `image: <loginServer>/our-image-name:v1`.

> `<loginServer>` should be replaced, as before.

Next, update `deployment.yaml` to use this value.

> Helm uses the syntax `{{ .Values.variableName }}` in templates (using Go templates).

You can run `helm template ./workshop-helm-chart` to preview your changes and see what will get deployed.
Once you're happy with the template, try upgrading the chart to use the new image: `helm upgrade my-chart ./workshop-helm-chart`.

If you run `kubectl get pods`, then you'll notice that our Pods aren't able to pull the image that we've just published.
However, we can use a Secret to give our cluster access to the registry, letting the Pods pull the image.

### Configuring permissions

> The syntax for variables and line endings will depend on your terminal.
> The examples shown here work in Bash.

First, let's enable our registry's admin user so we can manage credentials:

```bash
az acr update -n myregistryname --admin-enabled true
```

Next, let's retrieve some credentials that can be used to access the registry:

```bash
LOGIN_SERVER=<loginServer> # `<loginServer>` should be replaced, as before
ACR_USERNAME=$(az acr credential show -n $LOGIN_SERVER --query="username" -o tsv)
ACR_PASSWORD=$(az acr credential show -n $LOGIN_SERVER --query="passwords[0].value" -o tsv)
```

We can then create a Secret with those credentials:

```bash
kubectl create secret docker-registry acr-secret \
    --docker-server=$LOGIN_SERVER \
    --docker-username=$ACR_USERNAME \
    --docker-password=$ACR_PASSWORD
```

> Note that the multi-line delimiter `\` is for sh-based shells only, for powershell you'll want to use the backtick symbol ` instead

Now that we have a Secret, we can update `deployment.yaml` to use it:

<!-- prettier-ignore-start -->
```yaml
spec:
  containers:
    - name: container-name
      image: {{ .Values.image }}
      ports:
        - containerPort: 80
  imagePullSecrets:
    - name: acr-secret
```
<!-- prettier-ignore-end -->

Finally, we can deploy our changes by upgrading the chart:

```bash
helm upgrade my-chart ./workshop-helm-chart
```

The Helm chart and its dependencies should now deploy. The load balancer will be up and running, and the pods should successfully pull the image. However, the application will fail to start up because it's missing required environment variables.

## Environment variables & secrets

Now that your containers are being deployed correctly we'll want to pass through the appropriate environment variables to link up to the "finance" service. We have provided a copy of the application running as an app service, which you can use for comparison to get your version working in Kubernetes. In the list of resources in Azure, you should see one available to you ending with `order-processing-app` in the name.
Inside there, find the order processing app service and look at its configuration for the environment variables. You need all of the database or "finance" related variables. The "scheduled job" variables are used by the app but are optional.

> Credentials like DB passwords should be stored as secrets.

You may want to look at the docs on [environment variables](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/), [creating secrets](https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/#create-a-secret) and [accessing secrets](https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/#define-container-environment-variables-using-secret-data).

> Note that the value of an environment variable must be a string. YAML automatically determines the datatype of the value but you can force a value to be a string by wrapping it in quotes.

Once this is complete you should be able to load up your service's external IP in your browser and see the dashboard of orders!

> If you are still seeing Nginx, you may just need to avoid your browser's cache. Either "hard refresh" the page (CTRL+SHIFT+R on Windows or CMD+SHIFT+R on a Mac), or open it in a Chrome Incognito tab.

Let's set the number of pods back down to two before continuing:

```bash
helm upgrade --set replicas=2 my-chart ./workshop-helm-chart
```

## Dealing with Services

We can simulate a high load on our Service by selecting the "High Load" option from the "scenario" dropdown at the top of the page.

Let's run `kubectl top pod` to watch the load on the application increase.

Our Pods don't currently have any resource constraints, so the increasing load will eventually use up all of the node's available resources.

Let's prevent that by adding some resource constraints to the Deployment ([you can add resource constraints to any item under `containers` in a deployment file](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#example-1)):

```yaml
resources:
  requests:
    memory: "0.5Gi"
    cpu: "500m"
  limits:
    memory: "0.5Gi"
    cpu: "500m"
```

The `requests` fields set the minimum resources available to a Pod, while the `limits` fields set the maximums.

> Kubernetes assigns a [Quality of Service (QoS)](https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/) class to each Pod, which reflects how responsive it is likely to be.
> Setting the `requests` and `limits` fields to the same value gives the Pod a `Guaranteed` QoS level.

But what if we want to be able to scale up and handle peaks in demand while staying within resource limits?
We could use a HorizontalPodAutoscaler to automatically spin Pods up and down depending on the application load. Create a new yaml file in the templates folder with the following content:

<!-- prettier-ignore-start -->
```yaml
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
  name: {{ .Values.serviceName }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ .Values.serviceName }}
  minReplicas: 1
  maxReplicas: 8
  targetCPUUtilizationPercentage: 80
```
<!-- prettier-ignore-end -->

Now if we watch the load on the Node, we would see more Pods being spun up as the CPU utilisation increases if the cluster had space for them.

Unfortunately, we'll the hit resource limits of our Node (5\*500m CPU = 2.5 CPUs), which is more than we've allocated to our Node.
However, we can use a cluster autoscaler to automatically create more Nodes.

```bash
az aks update \
  --resource-group myResourceGroup \
  --name myAKSCluster \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 3
```

This should automatically scale up our cluster during high load, which we can watch happen by looking at the Nodes:

```bash
kubectl get node
```

If we change our Service back to the initial, lower load, we should see our Service reduce load gradually. Use the scenario picker at the top of the page to do this.
We can watch this using `kubectl get node` and `kubectl get pod`.

You can also clear out the queue if it has grown out of control by selecting "Delete all orders".

## Extension exercises

> Kubernetes stores ephemeral logs for Pods, which you can view with the `kubectl logs` command.

We're currently scaling the app automatically, but we aren't monitoring how healthy the app is.
We can improve this by adding some probes, such as a startup probe.

### Startup probes

A startup probe checks whether an application is running.
If the probe notices that the application isn't running then it triggers the parent container's restart policy.

> The default restart policy is `Always`, which causes containers to restart whenever their application exits.
> This applies even if the exit code indicated success.

Startup probes should be declared within the `containers` block of the deployment manifest.
A typical startup probe definition could look like this:

```yaml
startupProbe:
  httpGet:
    path: /health
    port: 80
  failureThreshold: 20
  periodSeconds: 10
```

We don't have a healthcheck endpoint in our app, so lets add one that just returns 200.
We can then publish our app, along with our helm chart, and watch what happens.

### Persistent Volumes

The app stores the output images in a local folder.
If an image is processed by a different Pod to the one receiving the request then the output image will not be visible on the dashboard.

We can resolve this by attaching the same Persistent Volume to all our Pod instances.
Configure a Persistent Volume Claim using the `azurefile` Storage Class in your Helm Chart and mount the volumes in your Deployment definition.
AKS is able to dynamically provision Azure Files resources on request, so we do not need to manually create a Storage Account + Files resource.
See <https://docs.microsoft.com/en-us/azure/aks/azure-files-dynamic-pv#create-a-persistent-volume-claim>.

> You can set the `IMAGE_OUTPUT_FOLDER` environment variable to change where the processing app stores the images it creates.

The original App Service is also processing images, but is not connected to your Azure Files resource. Find this old App Service in the order-processing resource group in the Azure portal and change its configuration to set `SCHEDULED_JOB_ENABLED=false`, so that only your cluster is processing images.

Now all images should show correctly for newly processed orders.

### Resource levels

Under normal load, the memory and CPU we allocated earlier might be much more than needed.
Tune the resource allocations under normal and heavy load and see how the application response to traffic spikes.
You can use the `kubectl top` command to view resource utilisation on Nodes and Pods.

### Incorporating the Finance Package

Up to now we've only been working with one Docker image (for the Order Processing app) and the corresponding pods connect to the Finance Package app deployed on Azure. Let's now try incorporating the Finance Package within the cluster.

> The Docker Hub image for the Finance Package app is available under the name `corndeldevopscourse/m13-finance-package`

Like with the Order Processing app, you'll need to scrape the environment variables from the app configuration.

You'll also want to set up a service so that the Order Processing app can access the Finance Package app and vice versa.

> Make sure not to expose the Finance Package externally!

Test that this is working by stopping both the non-Kubernetes app services through the Azure Portal, and check that your app keeps receiving and processing images.

### Security

We've so far only used a single service and exposed it fairly crudely, but what if we want a more advanced [ingress](https://docs.microsoft.com/en-us/azure/aks/ingress-basic)?
Try adding some RBAC rules for accessing DB credentials.
You could also add support for encrypting secrets.
