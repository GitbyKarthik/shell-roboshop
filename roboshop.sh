#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0da2b8c8343aa6f01"
ZONE_ID="Z0215693DLVU1UUNJSS6"
DOMAIN_NAME="dawsk86s.fun"

for instance in $@
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t3.micro --security-group-ids sg-0da2b8c8343aa6f01 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instance[0].InstanceId' --output text)

    if [ $instance != "frontend" ]; then
        IP=$(aws ec2 describe-instances --instance-ids i-0d32b66ecd303e445 --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
        RECORD_NAME="$instance.$DOMAIN_NAME" #mongodb.dawsk86s.fun
    else
        IP=$(aws ec2 describe-instances --instance-ids i-0d32b66ecd303e445 --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
        RECORD_NAME="$DOMAIN_NAME" #dawsk86s.fun
    fi

    echo "$instance: $IP"

    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
        "Comment": "Updating record set"
        ,"Changes": [{
        "Action"              : "UPSERT"
        ,"ResourceRecordSet"  : {
            "Name"              : "'$RECORD_NAME'"
            ,"Type"             : "A"
            ,"TTL"              : 1
            ,"ResourceRecords"  : [{
                "Value"         : "'$IP'"
            }]
        }
        }]
    }
    '
    
done
