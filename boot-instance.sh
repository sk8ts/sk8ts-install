#!/bin/bash

# For now we need an ami id
if [ -z "$1" ]; then
  echo "USAGE: $0 AMI-ID"
  echo "  You can also export:"
  echo "  -  SK8TS_INSTANCE_TYPE"
  echo "  -  SK8TS_VPC"
  echo "  -  SK8TS_SUBNET"
  echo "  -  SK8TS_SG_NAME"
  exit 1
else
  SK8TS_AMI=$1
fi

#
# Defaults
#

SK8TS_SG_NAME="${SK8TS_SG_NAME:-sk8ts-create-sg}"

# NOTE: Ran out of memory on copying files with ansible using a t2.micro
SK8TS_INSTANCE_TYPE="${SK8TS_INSTANCE_TYPE:-t2.medium}"

echo "INFO: AMI being used is ${SK8TS_AMI}"
echo "INFO: Instance type being used is ${SK8TS_INSTANCE_TYPE}"

#
# Check for aws cli
#

if ! command -v aws >/dev/null 2>&1; then
  echo "ERROR: Requires aws cli"
  echo "  run pip install awscli"
  exit 1
fi

#
# Find a VPC to use.
#

# Just pick the first VPC
if [ -z "${SK8TS_VPC}" ]; then
  DEFAULT_VPC=`aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --output text | grep VPCS | cut -f 7 | head -1`
else
  DEFAULT_VPC=${SK8TS_VPC}
fi

if [ -z "$DEFAULT_VPC" ]; then
  echo "ERROR: Couldn't find a default VPC"
  exit 1
fi

echo "INFO: Default VPC is ${DEFAULT_VPC}"


#
# Get a subnet. Needed to run create-instance.
#

# FIXME: Should check if getting a default public IP as well in filter
if [ -z "${SK8TS_SUBNET}" ]; then
  DEFAULT_SUBNET=`aws ec2 describe-subnets --filters "Name=vpcId,Values=${DEFAULT_VPC}" --output text | grep SUBNETS | cut -f 8 | head -1`
else
  DEFAULT_SUBNET="${SK8TS_SUBNET}"
fi

if [ -z "$DEFAULT_SUBNET" ]; then
  echo "ERROR: Couldn't find default subnet"
  exit 1
fi

echo "INFO: Default subnet is $DEFAULT_SUBNET"

#
# Now build a security group and allow port 22 from 0.0.0.0/0.
#

if ! aws ec2 describe-security-groups --output text | grep $SK8TS_SG_NAME > /dev/null; then
  echo "INFO: Creating security group"
  SG_ID=`aws ec2 create-security-group \
    --group-name $SK8TS_SG_NAME \
    --description "Security group for sk8ts-create instance" \
    --vpc-id $DEFAULT_VPC \
    --output text`
else
  SG_ID=`aws ec2 describe-security-groups --output text | grep $SK8TS_SG_NAME | cut -f 3` 
fi

echo "INFO: Ensuring $SG_ID allows port 22 from 0.0.0.0/0"
# It's ok to keep running this and ignore the output I guess
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0 > /dev/null 2>&1

#
# Find an ssh access key to use 
#

if [ -z "${SK8TS_SSH_KEY_NAME}" ]; then
  # Just pick the first key?
  DEFAULT_KEY=`aws iam list-access-keys --output text | cut -f 5 | head -1`
else
  DEFAULT_SUBNET="${SK8TS_SSH_KEY_NAME}"
fi

if [ -z "$DEFAULT_KEY" ]; then
  echo "ERROR: Could not find any access keys"
  exit 1
fi

echo "INFO: Access key being used is $DEFAULT_KEY"

#
# Finally run an instance
#

if ! aws ec2 run-instances \
  --image-id $SK8TS_AMI \
  --count 1 \
  --instance-type $SK8TS_INSTANCE_TYPE \
  --key-name $DEFAULT_KEY \
  --security-group-ids $SG_ID \
  --subnet-id $DEFAULT_SUBNET \
  --iam-instance-profile Name="sk8ts-create-instance-profile" \
  --associate-public-ip-address; then
  echo "ERROR: Could not boot instance"
else
  echo "INFO: Created instance"
fi
