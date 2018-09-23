## Deployment of Sentry

We are using a `docker-compose.yaml` file that is copied from [Official Sentry Installation](https://github.com/getsentry/onpremise/blob/master/docker-compose.yml), slightly modified to v3 of docker-compose so `kompose`(mentioned below) can be used.

Build your [sentry image](https://github.com/getsentry/onpremise) and push it to a registry. If you are using Google Cloud, you may follow [this guide](https://cloud.google.com/container-registry/docs/pushing-and-pulling).

Update `YOUR_IMAGE_LINK` in docker-compose.yaml

### Locally

First do `docker-compose run web config generate-secret-key` and populate the SENTRY_SECRET_KEY in docker-compose.yaml

`docker-compose up`

### On Kubernetes (Google Cloud)

#### Step 1: Generating Kubernetes Deployment Configurations

Using [kompose](http://kompose.io/), you can generate a series of deployment configs to run in kubernetes.

`kompose convert`

#### Step 2: Manually moving sentry containers into the same pod

You will immediately get a lot of deployment configurations that you can run in kubernetes using `kubectl create -f <your_deployment_config>`.

The problem, though, is that a few of our sentry containers share the same volume and they will run in different pods based on the configuration spit out by `kompose`. The volume does not allow multiple pods to access it. One solution is to run the containers on the same pod.

1. Create a new deployment config. `cp web-deployment sentry-deployment.yaml`.
2. Look into contents of `worker-deployment.yaml`, and copy contents under `containers:` section. For example:

```
...
containers:
#### Start copy ####
- args:
  - run
  - worker
  env:
  - name: SENTRY_EMAIL_HOST
    value: smtp
  - name: SENTRY_MEMCACHED_HOST
    value: memcached
  - name: SENTRY_POSTGRES_HOST
    value: postgres
  - name: SENTRY_REDIS_HOST
    value: redis
  - name: SENTRY_SECRET_KEY
    value: <YOUR_SECRET_KEY>
  image: <YOUR_IMAGE_LINK>
  name: worker
  resources: {}
  volumeMounts:
  - mountPath: /var/lib/sentry/files
    name: sentry-data
#### End copy ####
...
```

3. Paste the copied contents into `sentry-deployment.yaml` under the `containers` section so we create multiple containers in the pod
4. Copy and paste contents in the same way for `worker-deployment.yaml`
5. Delete the old deployment configuration files. `rm worker-deployment.yaml web-deployment.yaml cron-deployment.yaml`

#### Step 3: Run all the deployment configs in kubernetes

1. Create your volumes first:

```
kubectl create -f sentry-postgres-persistentvolumeclaim.yaml
kubectl create -f sentry-data-persistentvolumeclaim.yaml
```

2. Create non-sentry deployments:

```
kubectl create -f memcached-deployment.yaml
kubectl create -f postgres-deployment.yaml
kubectl create -f redis-deployment.yaml
kubectl create -f smtp-deployment.yaml
```

3. On kubernetes, expose `memcached`, `postgres`, `redis` and `smtp` via services so that sentry can reach them

4. Create an ad-hoc deployment to run sentry migrations:

```
kubectl create -f upgrade-deployment.yaml
```

Shut off `upgrade` once it is done

5. Create sentry deployment

```
kubectl create -f sentry-deployment.yaml
```

6. Expose `sentry` via services to port 9000 (or wherever sentry web is running) so that your sentry can be accessed

7. Go into the sentry pod and create the first admin user

`kubectl exec <sentry_pod_id> -- /bin/sh`

`sentry createuser`

Follow the prompts thereafter.

8. Go to your sentry instance on the web and access using the created user credentials
