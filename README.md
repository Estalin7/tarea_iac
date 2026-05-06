# tarea_iac— Image Processor (IaC con Terraform)

Arquitectura serverless en AWS para subir imágenes y recortarlas en PNGs circulares de 40×40 px.  
Desplegable en 3 entornos: **dev**, **qa** y **prod**.


# AWS CLI (ya está en Codespaces, solo configurar)
aws configure
# Ingresar: Access Key ID, Secret Access Key, Region (us-east-1), output (json)

# Node.js 20 (verificar)
node --version
```
Se agrego la Seguridad y Almacenamiento (Amazon S3)
La configuración del almacenamiento sigue las mejores prácticas de seguridad recomendadas por el **Terraform Registry** y el AWS Well-Architected Framework:

> **Nota:** Todos los recursos y sus configuraciones de seguridad se han extraído y adaptado de la documentación oficial del [Terraform Registry (AWS Provider)](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_encryption_by_default).

1. Arquitectura del Sistema
El proyecto implementa un flujo serverless para la ingesta y procesamiento de imágenes:
Entrada: API Gateway (HTTP API v2) recibe imágenes via POST.
Almacenamiento Inicial: Lambda de carga guarda en S3 ( uploads/ ).
Mensajería: Notificación S3 -> Cola SQS con DLQ para reintentos fallidos.
Procesamiento: Lambda Crop usa la librería sharp para transformar la imagen a 40x40 circular.
Salida: Imagen procesada en S3 ( processed/ ).

2. Comandos de Terraform Utilizados
# Inicializa el backend y descarga los proveedores (AWS, Archive)
terraform init
# Valida que la configuración sea sintácticamente correcta
terraform validate
# Crea un plan de ejecución y lo guarda en un archivo
terraform plan 
# Aplica los cambios en tu cuenta de AWS
terraform apply 

3. Pasos de Desarrollo (Work-log)

Paso 1: Configuración de Red (VPC) y conectividad privada mediante S3/SQS Endpoints.

Paso 2: Definición de Almacenamiento (S3) y Lógica de Colas (SQS + DLQ).

Paso 3: Desarrollo de Funciones Lambda en Node.js y empaquetado automático ZIP.

Paso 4: Creación de API Gateway, Rutas, CORS y permisos de invocación IAM.

Paso 5: Implementación de Observabilidad (Logs en CloudWatch y Alarmas de DLQ).

4. Prueba de Integración
Usa este comando curl para verificar el flujo completo:

5. Limpieza
Para eliminar todos los recursos y evitar cargos en AWS:
curl -X POST https://$(terraform output -raw api_url)/upload \
-H "Content-Type: image/jpeg" \
--data-binary "@mi_foto.jpg"

terraform destroy