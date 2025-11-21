import boto3
from botocore.exceptions import ClientError

s3 = boto3.client('s3')
ec2 = boto3.client('ec2')

# Defino variable de nombre del bucket
bucket_name = 'test-obligatorio-devops-martinez-ourthe-cabale'

# Seleccionamos la región
ec2 = boto3.client("ec2", region_name="us-east-1")

# Obtenemos VPC ID
try:
    vpcs = ec2.describe_vpcs(Filters=[{'Name': 'isDefault', 'Values': ['true']}])
    vpc_id = vpcs['Vpcs'][0]['VpcId']
    print(f"Usando VPC ID: {vpc_id}")
except Exception:
    print("No se pudo obtener la VPC por defecto. Verifica tu región o cuenta.")
    exit(1)

# Crear un bucket de S3
try:
    s3.create_bucket(Bucket=bucket_name)
    print(f"Bucket creado: {bucket_name}")
except ClientError as e:
    if e.response['Error']['Code'] == 'BucketAlreadyOwnedByYou':
        print(f"El bucket {bucket_name} ya existe y es tuyo.")
    else:
        print(f"Error creando bucket: {e}")
        exit(1)

AMI = 'ami-06b21ccaeff8cd686' 
SG_NAME_HTTP = 'http-sg'
DESCRIPTION_HTTP = 'Security group conexion http para mi instancia EC2'
INSTANCE_NAME = 'Http-server' 

SG_NAME_MYSQL = 'mysql-sg'
DESCRIPTION_MYSQL = 'Security group conexion mysql para mi instancia EC2'


# Crear primer Security Group http
sg_name_1 = 'http-sg'
try:
    response = ec2.create_security_group(
    GroupName=SG_NAME_HTTP,
    Description=DESCRIPTION_HTTP,
    VpcId=vpc_id
    )
    sg_id_1 = response['GroupId']
    print(f"Security Group creado: {sg_id_1}")
    
    # Permitir conexión http (puerto 80) desde cualquier lugar
    ec2.authorize_security_group_ingress(
        GroupId=sg_id_1,
        IpPermissions=[
            {
                'IpProtocol': 'tcp',
                'FromPort': 80,
                'ToPort': 80,
                'IpRanges': [{'CidrIp': '0.0.0.0/0'}]
            }
        ]
    )
except ClientError as e:
    if 'InvalidGroup.Duplicate' in str(e):
        sg_id_1 = ec2.describe_security_groups(GroupNames=[sg_name_1])['SecurityGroups'][0]['GroupId']
        print(f"Security Group ya existe: {sg_id_1}")
    else:
        raise

# Crear segundo Security Group
sg_name_2 = 'mysql-sg'
try:
    response = ec2.create_security_group(
    GroupName=SG_NAME_MYSQL,
    Description=DESCRIPTION_MYSQL,
    VpcId=vpc_id
    )
    sg_id_2 = response['GroupId']
    print(f"Security Group creado: {sg_id_2}")

    # Permitir conexión mysql (puerto 3306)
    ec2.authorize_security_group_ingress(
        GroupId=sg_id_2,
        IpPermissions=[
            {
                'IpProtocol': 'tcp',
                'FromPort': 3306,
                'ToPort': 3306,
                'UserIdGroupPairs': [{'GroupId': sg_id_1}]
            }
        ]
    )
except ClientError as e:
    if 'InvalidGroup.Duplicate' in str(e):
        sg_id_2 = ec2.describe_security_groups(GroupNames=[sg_name_2])['SecurityGroups'][0]['GroupId']
        print(f"Security Group ya existe: {sg_id_2}")
    else:
        raise

# Crear la instancia EC2 y asociar el Security Group
instance = ec2.run_instances(
    ImageId=AMI,
    InstanceType='t2.micro',
    SecurityGroupIds=[sg_id_1],
    MinCount=1,
    MaxCount=1,
    UserData="""#!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "Hello, World!" > /var/www/html/index.html
    """,
    IamInstanceProfile={
        'Name': 'LabInstanceProfile'  # Cambia por tu perfil de instancia IAM si es necesario
    }
)
instance_id = instance["Instances"][0]["InstanceId"]

# Agregar tag Name a la instancia
ec2.create_tags(
    Resources=[instance_id],
    Tags=[{'Key': 'Name', 'Value': INSTANCE_NAME}]
)

print(f'Instancia creada con ID: {instance_id}')