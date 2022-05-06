
#!/bin/bash

AmazonAMI="ami-0f9fc25dd2506cf6d"
Keypair="firstkey"
KeypairOhio="zdorova"
type="t2.micro"

Assign8id=$(aws ec2 create-security-group --group-name Assign8 --description "Assignment8" --query 'GroupId' --output text)
echo "SG is created"

aws ec2 authorize-security-group-ingress --group-name Assign8 --protocol tcp --port 80 --cidr 0.0.0.0/0

Insta1=$(aws ec2 run-instances --image-id "$AmazonAMI" --instance-type t2.nano --key-name "$Keypair" --associate-public-ip-address --user-data file://assig8data.txt --security-group-ids "$Assign8id" --region us-east-1 --query 'Instances[0].InstanceId' --output text)

echo "vse sdelal"

aws ec2 wait instance-running --instance-ids "$Insta1" --region us-east-1

echo "ec2 in us-east-1 has been created"


AMIVirginia=$(aws ec2 create-image --instance-id "$Insta1" --name AMIassign8V --query 'ImageId' --output text)

aws ec2 wait image-available\
    --image-ids "$AMIVirginia"
echo "image in virginia is created"

ec2fromAMI=$(aws ec2 run-instances --image-id "$AMIVirginia" --instance-type t2.nano\
    --key-name "$Keypair" --associate-public-ip-address\
    --security-group-ids "$Assign8id" --region us-east-1\
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=NVinstance2}]'\
    --query 'Instances[0].InstanceId' --output text)

AMIOhio=$(aws ec2 copy-image \
    --region us-east-2 \
    --name Ass8Ohio \
    --source-region us-east-1 \
    --source-image-id "$AMIVirginia" \
    --description "This is my copied image." --query 'ImageId' --output text)

aws ec2 wait image-available\
    --image-ids "$AMIOhio" --region us-east-2
echo "image in ohio is created"

Assign8idOhio=$(aws ec2 create-security-group --group-name Assign8Ohio --description "Assignment8" --region us-east-2 --query 'GroupId' --output text)
echo "SG Ohio is created"

aws ec2 authorize-security-group-ingress --group-name Assign8Ohio --region us-east-2 --protocol tcp --port 80 --cidr 0.0.0.0/0

Ohioec2inst=$(aws ec2 run-instances --image-id "$AMIOhio" --instance-type t2.nano --security-group-ids "$Assign8idOhio" --key-name "$KeypairOhio" --associate-public-ip-address  --region us-east-2 --query 'Instances[0].InstanceId' --output text)

aws ec2 wait instance-running\
    --instance-id "$Ohioec2inst"\
    --region us-east-2
echo "ec2 in Ohio has been created"

#task 3

publicIP=$(aws ec2 describe-instances --instance-ids $ec2fromAMI\
    --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

ssh -i "$Keypair" -o StrictHostKeyChecking=no ec2-user@"$publicIP" << EOF
  free -m
  exit
EOF

aws ec2 stop-instances --instance-ids "$ec2fromAMI"
echo "stopping an instance '$ec2fromAMI'"

aws ec2 wait instance-stopped --instance-ids "$ec2fromAMI"

aws ec2 modify-instance-attribute\
    --instance-id "$ec2fromAMI"\
    --instance-type "$type"

aws ec2 start-instances --instance-ids "$ec2fromAMI"
echo "starting an instance with new type"

aws ec2 wait instance-running --instance-ids "$ec2fromAMI"
echo "ec2 has been started"
sleep 30

publicIP_2=$(aws ec2 describe-instances --instance-ids "$ec2fromAMI"\
    --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

ssh -i "$Keypair" -o StrictHostKeyChecking=no ec2-user@"$publicIP_2" << EOF
  free -m
  exit
EOF

echo "zadanie sdelano"
