#  AWS Serverless Image Processor (IaC con Terraform)

Arquitectura **serverless** orientada a eventos diseñada para la carga y el procesamiento automatizado de imágenes. El sistema transforma imágenes cargadas en archivos **PNG circulares de 40×40 px** utilizando Node.js y la librería Sharp.

##  Arquitectura General

El flujo de datos sigue el principio de **mínimo privilegio** y **alta disponibilidad**:

* **Ingesta:** Cliente → `POST /upload` a través de **API Gateway HTTP API v2**.
* **Carga:** **Lambda Upload** procesa el binario y almacena la imagen original en **S3** (`uploads/`).
* **Evento:** S3 dispara una notificación hacia una **SQS Queue** para desacoplar el procesamiento.
* **Procesamiento:** **Lambda Crop** (con Sharp) consume la cola, recorta la imagen a 40x40 circular y guarda el resultado en S3 (`processed/`).
* **Resiliencia:** Si el procesamiento falla 3 veces, el mensaje se mueve a una **Dead Letter Queue (DLQ)**, disparando una **Alarma de CloudWatch**.

---

##  Estructura del Proyecto

```text
├── iac/                     # Infraestructura como Código (Terraform)
│   ├── environments/        # Configuraciones por entorno (dev, qa, prod)
│   │   └── dev/
│   │       └── terraform.tfvars
│   ├── main.tf              # Locals y Data Sources
│   ├── provider.tf          # Configuración del AWS Provider
│   ├── variables.tf         # Definición de variables globales
│   ├── outputs.tf           # Valores de salida (URLs, nombres de recursos)
│   ├── vpc.tf               # Networking: VPC, Subnets, NAT GW, VPC Endpoints
│   ├── s3.tf                # Storage: Buckets, SSE, Notificaciones
│   ├── sqs.tf               # Mensajería: Cola principal, DLQ y Alarmas
│   ├── iam.tf               # Seguridad: Roles y Políticas de IAM
│   ├── lambda.tf            # Cómputo: Funciones Lambda y Triggers
│   └── apigw.tf             # Entrada: API Gateway v2 y Rutas
└── src/lambda/              # Código fuente de las funciones (Node.js)
    ├── upload/              # Lógica de recepción de archivos
    └── crop/                # Lógica de procesamiento de imagen (Sharp)
 Requisitos Previos
Asegúrate de tener configurado el entorno antes de iniciar:

Configurar AWS CLI (us-east-1 recomendado):

Bash
aws configure
Verificar versiones de herramientas:

Bash
terraform --version
node --version # Requerido: v20.x
 Paso a Paso para el Despliegue
1. Personalización de Entorno
Abre el archivo iac/environments/dev/terraform.tfvars y asigna un sufijo único:

Terraform
suffix = "123456" # Usa los últimos 6 dígitos de tu cuenta AWS



 Ejecución de Terraform (Entorno DEV)
Bash
cd iac
terraform init
terraform workspace new dev
terraform apply 
Pruebas del Endpoint
Una vez desplegado, utiliza el output de la URL para probar la carga:

Bash
# Obtener URL automáticamente
API_URL=$(terraform output -raw api_url)

# Enviar imagen de prueba
curl -X POST "${API_URL}/upload" -F "image=@/ruta/a/tu_foto.jpg"
Respuesta Exitosa Esperada:

JSON
{
  "message": "Imagen subida correctamente",
  "imageId": "550e8400-e29b-41d4-a716-446655440000",
  "key": "uploads/nombre_archivo.jpg",
  "size": 204800
}
 Monitoreo y Salidas
Puedes consultar los datos clave en cualquier momento:

terraform output api_url: URL pública para carga de imágenes.

terraform output bucket_name: Identificador del bucket S3.

terraform output sqs_queue_url: Endpoint de la cola de mensajes.

 Limpieza de Recursos
Para evitar costos innecesarios:

Bash
terraform workspace select dev
terraform destroy 

---

