#!/bin/bash

if ! command -v aws >/dev/null 2>&1; then
  echo "ERROR: Requires aws cli"
  echo "  run pip install awscli"
  exit 1
fi

ROLE=sk8ts-create

if ! aws iam get-role --role-name $ROLE 2>&1 > /dev/null; then
  echo "INFO: Creating role..."

  aws iam create-role \
    --role-name $ROLE \
    --assume-role-policy-document file://aws-iam-policies/sk8ts-assume-role-policy-document.json

  aws iam put-role-policy \
    --role-name $ROLE \
    --policy-name sk8ts-create-policy \
    --policy-document file://aws-iam-policies/sk8ts-iam-policy.json

  aws iam create-instance-profile \
    --instance-profile-name sk8ts-create-instance-profile

  aws iam add-role-to-instance-profile \
    --instance-profile-name sk8ts-create-instance-profile \
    --role-name $ROLE 
  echo "INFO: Done creating role"
else
  echo "INFO: ${ROLE} already exists, not creating..."
  exit 0
fi

exit 0
