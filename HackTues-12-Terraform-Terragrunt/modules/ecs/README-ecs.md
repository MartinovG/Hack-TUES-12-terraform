
## Log in into the container

### Prerequisets

- Install AWS cli2 on your local machine (https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions)
- Install AWS Session Manager plugin (https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html#install-plugin-verify)
- Configure AWS SSO - follow these intructions for AWS CLI configuration: https://docs.aws.amazon.com/cli/latest/userguide/sso-configure-profile-token.html#sso-configure-profile-token-auto-sso. In a nut shell start with this:

```shell
$ aws configure sso
SSO session name (Recommended): ganchevs
SSO start URL [None]: https://d-9367012539.awsapps.com/start/
SSO region [None]: us-east-1
SSO registration scopes [sso:account:access]: <leave it empty>
CLI default client Region [None]: us-east-1
CLI default output format [None]: json
CLI profile name []: ro-dev

# for Linux
$ export AWS_PROFILE=ro-dev

# for Windows
C:\> $env:AWS_PROFILE='ro-dev'
```

Once the session expires, you need to login again (https://docs.aws.amazon.com/cli/latest/userguide/sso-using-profile.html):

```shell
$ aws sso login --profile ro-dev
```


Note: you need the Task ID which can be obtained from the AWS ECS console

For Linux
```shell
aws ecs describe-tasks \
    --cluster dev-ro-cluster \
    --region eu-west-1 \
    --tasks 32878bb6308d44fcbee3e090db4b6577

aws ecs execute-command  \
    --region eu-west-1 \
    --cluster dev-ro-cluster \
    --task 32878bb6308d44fcbee3e090db4b6577 \
    --container dev-ro-core-application \
    --command "/bin/bash" \
    --interactive
```

for Windows
```shell
aws ecs describe-tasks --cluster dev-ro-cluster --region eu-west-1 --tasks 32878bb6308d44fcbee3e090db4b6577

aws ecs execute-command --region eu-west-1 --cluster dev-ro-cluster --task 32878bb6308d44fcbee3e090db4b6577 --container dev-ro-core-application --command "/bin/bash" --interactive
```