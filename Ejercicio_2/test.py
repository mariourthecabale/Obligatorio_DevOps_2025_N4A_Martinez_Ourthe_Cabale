import boto3

ec2 = boto3.client('ec2')  # usa region por defecto o pon region_name='…'

def listar_instancias():
    response = ec2.describe_instances()
    instance_ids = []
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instance_id = instance['InstanceId']
            instance_ids.append(instance_id)
            print("Instance ID:", instance_id)
    return instance_ids

if __name__ == "__main__":
    ids = listar_instancias()
    print("Todas las instancias:", ids)
