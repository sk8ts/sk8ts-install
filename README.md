# sk8ts-install

The current workflow is to create an AWS virtual machine based on the sk8ts-ami image and provide it an IAM role with enough permissions to generate the required AWS infrastructure. Then that instance can use sk8ts to deploy Kubernetes.

More to come...

## Step -1: Ensure the region is clear of previous installations

Please ensure that if this process has been used previously that all of the:

* Instances
* Security groups
* VPCs
* Route tables
* IAM Roles
* Instance Profiles

have been removed. It's not strictly necessary, but there are some issues with idempotency and Ansible + AWS, such as perhaps route tables not being updated to use a new NAT gateway and the like. Better to remove all previous resources assocated with sk8ts.

## Step 0: Checkout all required repositories

For this example we will use the base directory of ~/sk8ts.

```
$ mkdir ~/sk8ts
$ cd sk8ts
$ git checkout https://github.com/sk8ts/sk8ts-install
$ git checkout https://github.com/sk8ts/sk8ts-ami
```

## Requirements

* awscli command installed
* packer binary
* AWS credentials in environment

## Step 1: Create AMI Image

This image will contain all of the required binaries to setup Kubernetes and it's infrastructure. It will also be the place that Ansible is run from.

Ensure you have your AWS credentials in your environment. The packer build requires three AWS environment variables:

```
AWS_SECRET_ACCESS_KEY
AWS_ACCESS_KEY_ID
AWS_REGION
```

Now build the AMI. You will need packer installed locally.

```
$ cd ~/sk8ts/sk8ts-ami
$ packer build sk8ts-ami.json
SNIP!
==> amazon-ebs: No volumes to clean up, skipping
==> amazon-ebs: Deleting temporary security group...
==> amazon-ebs: Deleting temporary keypair...
Build 'amazon-ebs' finished.

==> Builds finished. The artifacts of successful builds are:
--> amazon-ebs: AMIs were created:

us-west-2: ami-12345678
```

At the end of the packer run it returns an AMI ID.

NOTE: It can take some time for this AMI to be created because it has to download several large tar files.

## Step 2: Create a role for sk8ts

sk8ts requies an ec2 instance based on the previously created AMI. That image will create various AWS resources and it thus needs a role which has the privilieges to do that. So prior to creating that instance, we need to create the role.

Again, ensure your AWS environment variables are setup properly.

```
$ cd ~/sk8ts/sk8ts-install
$ ./create-role.sh
```

NOTE: This role will have considerable privilege in your AWS environment, so feel free to review the role and how it is created.

## Step 3: Create sk8ts instance

Now we need to create an instance from using that AMI assigned to the sk8ts-role.

```
$ cd ~/sk8ts/sk8ts-install
$ ./boot-instance.sh 
USAGE: ./boot-instance.sh AMI-ID
  You can also export:
  -  SK8TS_INSTANCE_TYPE
  -  SK8TS_VPC
  -  SK8TS_SUBNET
  -  SK8TS_SG_NAME
```

As shown above, the script requires input of the AMI ID that was created previously.

```
$ ./boot-instance.sh ami-12345678
SNIP!
INFO: Created instance
```

## Step 4: ssh into instance

Now that the instance has been created, you can ssh into it.

```
$ ssh ubuntu@<public ip>
SNIP!
ubuntu@ip-172-31-30-172:~$ ls /opt
sk8ts  sk8ts-venv
```

## Step 5: Deploy Kubernetes


## Step 6: Deploy Application

```
ubuntu@util0:~$ kubectl run my-nginx --image=nginx --replicas=2 --port=80
deployment "my-nginx" created
```

