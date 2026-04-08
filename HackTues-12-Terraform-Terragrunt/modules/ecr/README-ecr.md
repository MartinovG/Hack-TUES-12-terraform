# Example with the DEV environment

## Use this build command for the services:

```shell
$ aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 536697243063.dkr.ecr.us-east-1.amazonaws.com
$ docker build -t dev-route-optimizer-algorithms-repo --build-arg VERSION=8.3 --build-arg USER_ID=1000 --build-arg GROUP_ID=1000 .
$ docker tag dev-route-optimizer-algorithms-repo:latest 536697243063.dkr.ecr.us-east-1.amazonaws.com/dev-route-optimizer-algorithms-repo:latest
$ docker push 536697243063.dkr.ecr.us-east-1.amazonaws.com/dev-route-optimizer-algorithms-repo:latest
```

## Use this build command for the backend:

```shell
$ aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 536697243063.dkr.ecr.us-east-1.amazonaws.com
$ docker build -t dev-route-optimizer-backend-repo --build-arg VERSION=8.3 --build-arg USER_ID=1000 --build-arg GROUP_ID=1000 .
$ docker tag dev-route-optimizer-backend-repo:latest 536697243063.dkr.ecr.us-east-1.amazonaws.com/dev-route-optimizer-backend-repo:latest
$ docker push 536697243063.dkr.ecr.us-east-1.amazonaws.com/dev-route-optimizer-backend-repo:latest
```

## Use this build command for the frontend:

```shell
$ aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 536697243063.dkr.ecr.us-east-1.amazonaws.com
$ docker build -t dev-route-optimizer-frontend-repo --build-arg VERSION=8.3 --build-arg USER_ID=1000 --build-arg GROUP_ID=1000 .
$ docker tag dev-route-optimizer-frontend-repo:latest 536697243063.dkr.ecr.us-east-1.amazonaws.com/dev-route-optimizer-frontend-repo:latest
$ docker push 536697243063.dkr.ecr.us-east-1.amazonaws.com/dev-route-optimizer-frontend-repo:latest
```