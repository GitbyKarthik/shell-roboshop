#!/bin/bash

for instance in $@
do
    INSTANCE_ID=$(aws ec2 run-instances \
        --image-id $AMI_ID \
        --instance-type t3.micro \
        --security-group-ids $SG_ID \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
        --query 'Instances[0].InstanceId' \
        --output text)

    echo "Waiting for instance $INSTANCE_ID to be running..."
    aws ec2 wait instance-running --instance-ids $INSTANCE_ID

    if [ "$instance" != "frontend" ]; then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
            --query 'Reservations[0].Instances[0].PrivateIpAddress' \
            --output text)
        RECORD_NAME="$instance.$DOMAIN_NAME"
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
            --query 'Reservations[0].Instances[0].PublicIpAddress' \
            --output text)
        RECORD_NAME="$DOMAIN_NAME"
    fi

    echo "$instance: $IP"

    if [ "$IP" != "None" ] && [ -n "$IP" ]; then
        aws route53 change-resource-record-sets \
        --hosted-zone-id $ZONE_ID \
        --change-batch "
        {
            \"Comment\": \"Updating record set\",
            \"Changes\": [{
                \"Action\": \"UPSERT\",
                \"ResourceRecordSet\": {
                    \"Name\": \"$RECORD_NAME\",
                    \"Type\": \"A\",
                    \"TTL\": 300,
                    \"ResourceRecords\": [{\"Value\": \"$IP\"}]
                }
            }]
        }"
    else
        echo "❌ Skipping $instance: No valid IP found."
    fi

done
