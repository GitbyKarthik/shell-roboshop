#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0da2b8c8343aa6f01"

for instance in $@
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t3.micro --security-group-ids sg-0da2b8c8343aa6f01 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instance[0].InstanceId' --output text)

    if [ $instance != "frontend" ]; then
        IP=$(aws ec2 describe-instances --instance-ids i-0d32b66ecd303e445 --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
    else
        IP=$(aws ec2 describe-instances --instance-ids i-0d32b66ecd303e445 --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
    fi

    echo "$instance: $IP"
    
done