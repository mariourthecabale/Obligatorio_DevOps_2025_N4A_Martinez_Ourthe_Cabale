import boto3
import time
from botocore.exceptions import ClientError

ec2 = boto3.client('ec2', region_name='us-east-1')
ssm = boto3.client('ssm', region_name='us-east-1')

# Tu user_data
user_data = '''#!/bin/bash
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
'''

# Creás la instancia
response = ec2.run_instances(
    ImageId='ami-0fa3fe0fa7920f68e',
    InstanceType='t2.micro',
    MinCount=1,
    MaxCount=1,
    IamInstanceProfile={'Name': 'LabInstanceProfile'},
    UserData=user_data
)

instance_id = response['Instances'][0]['InstanceId']
print(f"Instancia creada con ID: {instance_id}")

# Esperar a que la instancia esté "running"
waiter = ec2.get_waiter('instance_running')
waiter.wait(InstanceIds=[instance_id])
print("Instancia ahora está running")

# Esperar un poco para que el agente SSM se registre (ajustá este sleep según lo que veas que demora)
time.sleep(60)

# Enviar comando via SSM
send_response = ssm.send_command(
    InstanceIds=[instance_id],
    DocumentName='AWS-RunShellScript',
    Parameters={
        'commands': [
            'aws s3 cp s3://obligatorio-devops-martinez-ourthe-cabale/archivos/ /var/www/html --recursive --exclude "*.sql" --exclude "README.md" && aws s3 cp s3://obligatorio-devops-martinez-ourthe-cabale/archivos/ /var/www/ --recursive --exclude "*" --include "*.sql"'
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
