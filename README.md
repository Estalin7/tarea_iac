# tarea_iac— Image Processor (IaC con Terraform)

Arquitectura serverless en AWS para subir imágenes y recortarlas en PNGs circulares de 40×40 px.  
Desplegable en 3 entornos: **dev**, **qa** y **prod**.



```bash
# AWS CLI (ya está en Codespaces, solo configurar)
aws configure
# Ingresar: Access Key ID, Secret Access Key, Region (us-east-1), output (json)

# Node.js 20 (verificar)
node --version
```
Se agrego la Seguridad y Almacenamiento (Amazon S3)
La configuración del almacenamiento sigue las mejores prácticas de seguridad recomendadas por el **Terraform Registry** y el AWS Well-Architected Framework:

> **Nota:** Todos los recursos y sus configuraciones de seguridad se han extraído y adaptado de la documentación oficial del [Terraform Registry (AWS Provider)](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ebs_encryption_by_default).