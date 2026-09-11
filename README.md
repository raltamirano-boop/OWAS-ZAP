# OWASP ZAP (Docker Compose)

Este repositorio contiene la configuración de Docker Compose para desplegar fácilmente una instancia de **OWASP ZAP** (Zed Attack Proxy) utilizando su interfaz gráfica a través del navegador (WebSwing).

## Requisitos previos

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Levantar el entorno

Para levantar el servicio de OWASP ZAP en segundo plano, ejecuta el siguiente comando en la raíz del proyecto:

```bash
docker-compose up -d
```

## Acceso

- **Interfaz Gráfica (WebSwing)**: Una vez que el contenedor esté en ejecución, puedes acceder a la interfaz de usuario directamente desde tu navegador en:  
  👉 [http://localhost:8090/zap](http://localhost:8090/zap)
- **Puerto Proxy / API**: El proxy y la API de ZAP están expuestos en el puerto `8081` (localhost:8081).

## Volúmenes y Reportes

El directorio local `./docs/security` está mapeado al directorio `/zap/wrk/` dentro del contenedor. Esto significa que cualquier reporte o archivo generado por ZAP dentro de la carpeta `wrk` se guardará automáticamente en tu máquina local en la ruta `docs/security/`.

## Detener el entorno

Para detener el contenedor, ejecuta:

```bash
docker-compose down
```
