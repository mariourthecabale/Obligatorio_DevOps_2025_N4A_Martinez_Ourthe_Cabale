import boto3

ec2 = boto3.client('ec2')

# Parámetro por defecto
image_id = 'ami-0fa3fe0fa7920f68e'
response = ec2.run_instances(
    ImageId=image_id,
    MinCount=1,
    MaxCount=1,
    InstanceType='t2.micro'
)

instance_id = response['Instances'][0]['InstanceId']
print("Instancia ID:", instance_id)

waiter = ec2.get_waiter('instance_running')
waiter.wait(InstanceIds=[instance_id])

print("La instancia ya está en estado running")