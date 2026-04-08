# Prerequisets

To connect to the databases you need to follow this:

- Install AWS cli2 on your local machine (https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions)
- Install AWS Session Manager plugin (https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html#install-plugin-verify)
- Install the database clients locally
      - MySQL client
            Download link: https://dev.mysql.com/downloads/workbench/
            User: nos_admin
            Password: 1-NOS_admin.2
      - Redis client
            Download link: https://goanother.com/
            SSL (TLS): yes
      - Mongo Compass
          - https://www.mongodb.com/try/download/compass
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

$ export AWS_PROFILE=ro-dev
```

Once the session expires, you need to login again (https://docs.aws.amazon.com/cli/latest/userguide/sso-using-profile.html):

```shell
$ aws sso login --profile ro-dev
```


# Start the Session Manager

- Create an IP tunneling without a need for SSH keys - Start a session (https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-sessions-start.html#sessions-start-port-forwarding)

For Windows PowerShell (example for DocumentDB):
```shell
aws ssm start-session `
     --target $(aws ec2 describe-instances --filters "Name=tag:Name,Values=dev-route-optimizer-bastion-host-private" --query "Reservations[*].Instances[*].InstanceId" --output text --region us-east-1 --profile ro-dev) `
     --document-name AWS-StartPortForwardingSessionToRemoteHost `
     --parameters host="dev-route-optimizer-mongo.cluster-ck9e8yogyxez.us-east-1.docdb.amazonaws.com",portNumber="27017",localPortNumber="27017" `
     --region us-east-1 `
     --profile ro-dev
```

For Linux (example for DocumentDB):
```shell
aws ssm start-session \
      --target $(aws ec2 describe-instances --filters "Name=tag:Name,Values=dev-route-optimizer-bastion-host-private" --query "Reservations[*].Instances[*].InstanceId" --output text --region us-east-1 --profile ro-dev) \
      --document-name AWS-StartPortForwardingSessionToRemoteHost \
      --parameters '{"host":["dev-route-optimizer-mongo.cluster-ck9e8yogyxez.us-east-1.docdb.amazonaws.com"],"portNumber":["27017"], "localPortNumber":["27017"]}' \
      --region us-east-1 \
      --profile ro-dev
```

## with TLS
Obtaing the .pem file and store it locally: wget https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem 
Start the Session Manager and do not close that window/terminal. Launch your database client and connect it to "mongodb://routingoptimizer:routingoptimizer@127.0.0.1:27017/?directConnection=true&tls=true&tlsAllowInvalidHostnames=true&tlsCAFile=<local-path-to.pem-file">
Enable: tlsAllowInvalidHostnames
Enable: DirectConnection
Connection String Scheme: mongodb

## without TLS
Start the Session Manager and do not close that window/terminal. Launch your database client and connect it to "mongodb://routingoptimizer:routingoptimizer@127.0.0.1:27017/?directConnection=true"