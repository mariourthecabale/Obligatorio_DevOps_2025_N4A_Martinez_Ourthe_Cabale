# Obligatorio_DevOps_2025_N4A_Martinez_Ourthe_Cabale
# Paso a paso para una correcta ejecución de los ejercicios 1 y 2

## Ejercicio 1

### 1. Instalación de Git (solo si no está instalado)

Si no tienes Git instalado en tu sistema, ejecuta:

```bash
sudo apt install git -y 
```
### 2. Clonar el repositorio del obligatorio
```bash
git clone https://github.com/mariourthecabale/Obligatorio_DevOps_2025_N4A_Martinez_Ourthe_Cabale.git
```
### 3. Posicionarse en la carpeta del Ejercicio 1
```bash
cd Obligatorio_DevOps_2025_N4A_Martinez_Ourthe_Cabale/Ejercicio_1
```
### 4. Ejecutar el script
Ejecutamos el script con todos los argumentos válidos.
La contraseña por defecto establecida es: 123456789
```bash
sudo ./ej1_crea_usuarios.sh -i -c "123456789" archivo_con_los_usuarios_a_crear.txt
```

## Ejercicio 2

### Pasos previos para la ejecucion del script para desplegar la aplicacion
##### 1. Si no tenes python3, pip y venv.

Ubuntu:
```bash
    sudo apt install python3-pip python3-venv
```
RedHat:
```bash
    sudo dnf install python3-pip
```

#### 2. Crear entorno virtual y activarlo
```bash
python -m venv .venv
```
```bash
source .venv/bin/activate
```

#### 3. Instalar libreria boto3 dentro del entorno virtual
```bash
pip install boto3
```

### Configurar AWS para utilizar desde la linea de comandos

#### 1. Iniciar el laboratorio en "AWS Academy Learner Lab"
![Start Lab](imagenes/sart_lab.jpg)

#### 2. Utilzar linea de comandos.
```bash
aws configure
```
#### 3. Ingresar datos solicitados
