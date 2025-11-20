import boto3
from botocore.exceptions import ClientError

s3 = boto3.client('s3')

# Parámetros por defecto
bucket_name = 'obligatorio-devops-martinez-ourthe-cabale'
file_path = 'archivo.txt'
object_name = file_path.split('/')[-1]

# Parte 1: Crear un bucket de S3
try:
    s3.create_bucket(Bucket=bucket_name)
    print(f"Bucket creado: {bucket_name}")
except ClientError as e:
    if e.response['Error']['Code'] == 'BucketAlreadyOwnedByYou':
        print(f"El bucket {bucket_name} ya existe y es tuyo.")
    else:
        print(f"Error creando bucket: {e}")
        exit(1)