import os
import boto3
from botocore.exceptions import ClientError

s3 = boto3.client('s3')

bucket_name = 'obligatorio-devops-martinez-ourthe-cabale'
folder = './archivos/'

# Crear el bucket si no existe (cuenta con errores)
try:
    s3.create_bucket(Bucket=bucket_name)
    print(f"Bucket creado: {bucket_name}")
except ClientError as e:
    if e.response['Error']['Code'] == 'BucketAlreadyOwnedByYou':
        print(f"El bucket {bucket_name} ya existe y es tuyo.")
    else:
        print(f"Error creando bucket: {e}")
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
