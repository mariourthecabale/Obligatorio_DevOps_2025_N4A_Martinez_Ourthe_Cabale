import boto3
import time
import os
from botocore.exceptions import ClientError
import getpass

s3 = boto3.client('s3')
ssm = boto3.client('ssm', region_name='us-east-1')
rds = boto3.client('rds')
# Seleccionamos la región
ec2 = boto3.client("ec2", region_name="us-east-1")
# Defino variable de nombre del bucket y carpeta a crear
bucket_name = 'obligatorio-devops-martinez-ourthe-cabale'
folder = './archivos/'

##Creamos el bucket
try:
    # Verificar si el bucket existe
    s3.head_bucket(Bucket=bucket_name)
    print(f"El bucket '{bucket_name}' ya existe.")
except ClientError as e:
    error_code = e.response.get('Error', {}).get('Code', '')
    # Si da error 404 → no existe → lo creamos
    if error_code in ('404', 'NoSuchBucket'):
        try:
            s3.create_bucket(Bucket=bucket_name)
            print(f"Bucket creado: {bucket_name}")
        except ClientError as e2:
            print(f"Error creando bucket: {e2}")
            exit(1)
    else:
        print(f"Error verificando bucket: {e}")
        exit(1)

# Recorrer los archivos del folder y subirlos
for filename in os.listdir(folder):
    local_path = os.path.join(folder, filename)
    object_name = f"archivos/{filename}"

    try:
        s3.upload_file(local_path, bucket_name, object_name)
        print(f"Subido {local_path} → s3://{bucket_name}/{object_name}")
    except ClientError as e:
        print(f"Error subiendo {local_path}: {e}")

AMI = 'ami-06b21ccaeff8cd686' 
SG_NAME_HTTP = 'http-sg-2'
DESCRIPTION_HTTP = 'Security group conexion http para mi instancia EC2'
INSTANCE_NAME = 'Http-server' 

SG_NAME_MYSQL = 'mysql-sg-2'
DESCRIPTION_MYSQL = 'Security group conexion mysql para mi instancia EC2'


# Crear primer Security Group http

try:
    response = ec2.create_security_group(
    GroupName=SG_NAME_HTTP,
    Description=DESCRIPTION_HTTP,
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
        sg_id_1 = ec2.describe_security_groups(GroupNames=[SG_NAME_HTTP])['SecurityGroups'][0]['GroupId']
        print(f"Security Group ya existe: {sg_id_1}")
    else:
        raise



# Crear segundo Security Group
try:
    response = ec2.create_security_group(
    GroupName=SG_NAME_MYSQL,
    Description=DESCRIPTION_MYSQL,
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
        sg_id_2 = ec2.describe_security_groups(GroupNames=[SG_NAME_MYSQL])['SecurityGroups'][0]['GroupId']
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
    UserData='''#!/bin/bash
    sudo dnf clean all
    sudo dnf makecache
    sudo dnf -y update
    sudo dnf -y install httpd php php-cli php-fpm php-common php-mysqlnd mariadb105
    sudo systemctl enable --now httpd
    sudo systemctl enable --now php-fpm
    echo '<FilesMatch \\.php$>
      SetHandler "proxy:unix:/run/php-fpm/www.sock|fcgi://localhost/"
    </FilesMatch>' | sudo tee /etc/httpd/conf.d/php-fpm.conf
    echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php
    sudo systemctl restart httpd php-fpm
    echo "¡Sitio personalizado!" | sudo tee /var/www/html/index.html
    ''',
    IamInstanceProfile={
        'Name': 'LabInstanceProfile'  
    }
)
instance_id = instance["Instances"][0]["InstanceId"]
print(f"Instancia creada con ID: {instance_id}")

# Esperar a que la instancia esté "running"
waiter = ec2.get_waiter('instance_running')
waiter.wait(InstanceIds=[instance_id])
print("Instancia ahora está running")

# Esperar un poco para que el agente SSM se registre
time.sleep(60)

# Enviar comando via SSM, para copiar archivos desde el bucket al servidor de aplicacion
send_response = ssm.send_command(
    InstanceIds=[instance_id],
    DocumentName='AWS-RunShellScript',
    Parameters={
        'commands': [
            'aws s3 cp s3://obligatorio-devops-martinez-ourthe-cabale/archivos/ /var/www/html --recursive --exclude "*.sql" --exclude "README.md" && aws s3 cp s3://obligatorio-devops-martinez-ourthe-cabale/archivos/ /var/www/ --recursive --exclude "*" --include "*.sql" --include ".env"',
            'sudo chown -R apache:apache /var/www/html'
        ]
    }
)

command_id = send_response['Command']['CommandId']
print(f"Comando enviado con CommandId: {command_id}")

# Esperar a que el comando termine y obtener su resultado
# Hacer polling con get_command_invocation
while True:
    invocation = ssm.get_command_invocation(CommandId=command_id, InstanceId=instance_id)
    status = invocation['Status']
    print(f"Estado del comando: {status}")
    if status in ('Success', 'Failed', 'TimedOut', 'Cancelled', 'DeliveryTimedOut'):
        break
    time.sleep(5)

print("Resultado del comando:")
print("STDOUT:", invocation.get('StandardOutputContent'))
print("STDERR:", invocation.get('StandardErrorContent'))


# Agregar tag Name a la instancia
ec2.create_tags(
    Resources=[instance_id],
    Tags=[{'Key': 'Name', 'Value': INSTANCE_NAME}]
)

print(f'Instancia creada con ID: {instance_id}')



##Creamos instancia RDS
DB_INSTANCE_ID = 'app-mysql'
DB_NAME = 'demo_db'
DB_USER = 'admin'
DB_PASS = getpass.getpass("Ingrese contraseña minimo de 8 caracteres: ")

#DB_PASS = os.environ.get('RDS_ADMIN_PASSWORD')

if not DB_PASS:
    raise Exception('Debes definir la variable de entorno RDS_ADMIN_PASSWORD con la contraseña del admin.')

try:
    rds.create_db_instance(
        DBInstanceIdentifier=DB_INSTANCE_ID,
        AllocatedStorage=20,
        VpcSecurityGroupIds=[sg_id_2],
        DBInstanceClass='db.t3.micro',
        Engine='mysql',
        MasterUsername=DB_USER,
        MasterUserPassword=DB_PASS,
        DBName=DB_NAME,
        PubliclyAccessible=True,
        BackupRetentionPeriod=0
    )
    print(f'Instancia RDS {DB_INSTANCE_ID} creada correctamente.')
except rds.exceptions.DBInstanceAlreadyExistsFault:
    print(f'La instancia {DB_INSTANCE_ID} ya existe.')

##Esperamos a que la base de datos este disponible
waiter = rds.get_waiter('db_instance_available')
try:
    print("Esperando a que la instancia RDS esté disponible ...")
    waiter.wait(DBInstanceIdentifier=DB_INSTANCE_ID,
                WaiterConfig={
                    'Delay': 15,        # tiempo de espera estandar
                    'MaxAttempts': 30   # tiempo de espera maximo   
                })
    print("RDS está disponible.")
    response_rds=rds.describe_db_instances(
        DBInstanceIdentifier=DB_INSTANCE_ID
    )
    db_instance = response_rds['DBInstances'][0]
    ENDOPOINT_ADDRESS = db_instance['Endpoint']['Address']

    command = (
    f"mysql -h {ENDOPOINT_ADDRESS} -u {DB_USER} -p{DB_PASS} {DB_NAME} < /var/www/init_db.sql"
    )
    send_response = ssm.send_command(
    InstanceIds=[instance_id],
    DocumentName='AWS-RunShellScript',
    Parameters={
        'commands': [command]
    }
)

except ClientError as e:
    print("Error esperando por RDS:", e)
    raise

send_response = ssm.send_command(
    InstanceIds=[instance_id],
    DocumentName='AWS-RunShellScript',
    Parameters={
        'commands': [ 
            """
            sudo tee /var/www/.env >/dev/null <<'ENV'
   DB_HOST=ENDOPOINT_ADDRESS
   DB_NAME=DB_NAME
   DB_USER=DB_USER
   DB_PASS=DB_PASS
   APP_USER=admin
   APP_PASS=admin123
   ENV

   sudo chown apache:apache /var/www/.env
   sudo chmod 600 /var/www/.env

   sudo systemctl restart httpd php-fpm
   """
        ]
    }
)
  