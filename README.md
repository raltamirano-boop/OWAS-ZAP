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

- **Modo Daemon / API**: Para poder automatizar las pruebas con el `Makefile`, ZAP se ejecuta en modo _Daemon_ (sin interfaz gráfica) exponiendo su API REST y Proxy en el puerto `8081` (localhost:8081). Esto es el estándar para pipelines DevSecOps.

## Volúmenes y Reportes

El directorio local `./docs/security` está mapeado al directorio `/zap/wrk/` dentro del contenedor. Esto significa que cualquier reporte o archivo generado por ZAP dentro de la carpeta `wrk` se guardará automáticamente en tu máquina local en la ruta `docs/security/`.

## Detener el entorno

Para detener el contenedor, ejecuta:

```bash
docker-compose down
```

## 🛡️ Pipeline Automático de Auditoría DevSecOps

Este proyecto incluye un pipeline automatizado para escanear el microservicio `cac-service` usando OWASP ZAP y analizar las vulnerabilidades de forma privada con el modelo de IA `qwen2.5-coder:7b` corriendo localmente en Ollama.

### Prerrequisitos

- Docker Compose en ejecución (`zap` y `ollama-llm`).
- Python 3 instalado con la librería `requests` (`pip install requests`).
- `make` instalado en el sistema.

### Pasos de Ejecución con Makefile

Puedes ejecutar el flujo paso a paso o todo en un solo comando:

1. **Importar especificación OpenAPI:**
   ```bash
   make import-api OPENAPI_URL=http://host.docker.internal:8080/v3/api-docs
   ```

2. **Ejecutar escaneo activo (Active Scan):**
   ```bash
   make scan TARGET_URL=http://host.docker.internal:8080
   ```

3. **Exportar el reporte JSON de ZAP:**
   ```bash
   make report
   ```

4. **Procesar alertas con Ollama y generar reporte Markdown:**
   ```bash
   make remediate
   ```

5. **Limpiar entorno y empezar de nuevo:**
   Si deseas borrar los reportes generados o eliminar todo el entorno (contenedores y volúmenes) para empezar desde cero, tienes dos opciones:
   - Para solo borrar los reportes localmente:
     ```bash
     make clean
     ```
   - Para borrar los reportes Y destruir los contenedores y sus volúmenes asociados:
     ```bash
     make reset
     ```

---

### Execución Completa (Un solo comando)

Para ejecutar todo el pipeline de principio a fin automáticamente:
```bash
make all
```

El reporte final con parches de código en Spring Boot se guardará en: `./docs/security/remediation-report.md`
