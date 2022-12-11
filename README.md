# Assigment

Hello there 👋

## What's done

- App using FastAPI. It exposes 6 endpoints:
  - ```/analyze_shared_crop``` - for analyzing 512px crop of satelite image
  - ```/metrcis``` - basic prometheus metrics
  - ```/health``` - health check
  - ```/docs``` ```/redoc``` - Swagger UI & ReDoc
- Dockerfile for building the app
- simple CI pipeline for building and pushing the image to Docker Hub
- Terraform code for deploying GKE and app
- Deployment ready for multi node cluster. As workaround for ReadWriteMany PVC (storage for satelite data and croped 512px images) I'm using NFS server deployment with persistent disk
- Horizontal Pod Autoscaler for the app

## What can be done better

### at the App code
- method for sliding though the full satelite image and processing it widow by window (not implemented yet)
- some pytests + utilizing them in CI
- better error handling and error messages
- logging
### at the deployment
- multi stage docker build to reduce image size, alpine distro as base image for build
- Helm chart for yaml's & using it via Terraform Helm provider
- Kustomize for yaml manifests (?) [not realy needed because of terraform]
- Filestore instad of NFS server

## Requirements

- git
- kubectl
- terraform
- gcloud

## How to deploy:

- clone the repository
- copy ```deploy/gke/terraform.tfvars.template``` to ```deploy/gke/terraform.tfvars``` and set ```project_id``` equal to your GCP project id
- run ```terraform -chdir=deploy/gke init``` to initialize terraform
- run ```terraform -chdir=deploy/gke apply``` to deploy GKE cluster
- copy ```deploy/app/terraform.tfvars.template``` to ```deploy/app/terraform.tfvars``` and edit ```kubeconfig_path``` (optional)
- run ```gcloud container clusters get-credentials CHANGE_ME-assigment-gke --zone europe-west4-a --project CHANGE_ME``` to prepare kubectl for the cluster
- run ```terraform -chdir=deploy/app init``` to initialize terraform
- run ```terraform -chdir=deploy/app apply``` to deploy the app
- run ```kubectl get all -n twentytrees-asgmt``` to see the result

## How to test:

For demo and testing I'm using pre-uploaded 512px image crop from satelite data. In real life it would be better to use some kind of batch processing to process all the images in the bucket.

- run ```kubectl port-forward service/analyzer-svc 8080:8080 -n twentytrees-asgmt```
- run ```time curl http://localhost:8080/analyze_shared_crop?image_path=satelite/test-crop-512x512.tif```

On GCP ```n1-standard-2``` instance it takes about 1s to process the image.

- for load testing you can run for example:

```kubectl run wrk --restart=Never --rm -it --tty --image skandyla/wrk -- -t1 -c2 -d60 'http://analyzer-svc.twentytrees-asgmt.svc.cluster.local:8080/analyze_shared_crop?image_path=satelite/test-crop-512x512.tif'```


and play with ```wrk``` parameters or/and change the cluster HPA settings