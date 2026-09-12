.PHONY: help import-api scan generate-report remediate all clean reset

# Variables
OPENAPI_URL ?= http://host.docker.internal:8080/v3/api-docs
TARGET_URL ?= http://host.docker.internal:8080
ZAP_CONTAINER = zap-dashboard
OLLAMA_CONTAINER = ollama-llm
MODEL_NAME ?= qwen2.5-coder:7b
REPORT_DIR = ./docs/security

help:
	@echo "Comandos disponibles:"
	@echo "  make up          - Levanta los contenedores en segundo plano (docker-compose up -d)"
	@echo "  make down        - Detiene los contenedores (docker-compose down)"
	@echo "  make pull-model  - Descarga el modelo de IA localmente en el contenedor de Ollama"
	@echo "  make import-api  - Importa la especificación OpenAPI en OWASP ZAP"
	@echo "  make scan        - Ejecuta el escaneo activo en OWASP ZAP"
	@echo "  make report      - Genera y exporta zap-report.json"
	@echo "  make remediate   - Procesa zap-report.json con Ollama y crea el reporte Markdown"
	@echo "  make all         - Ejecuta todo el flujo completo de DevSecOps"
	@echo "  make clean       - Elimina los reportes generados localmente"
	@echo "  make reset       - Elimina los reportes y baja los contenedores borrando sus volúmenes"

up:
	@echo "==> Levantando el entorno de contenedores..."
	docker-compose up -d
	@echo "==> Esperando a que ZAP inicie completamente (puede tomar ~40 segundos)..."
	@python3 wait_for_zap.py

down:
	@echo "==> Deteniendo el entorno de contenedores..."
	docker-compose down

pull-model:
	@echo "==> Descargando el modelo $(MODEL_NAME) en Ollama (esto puede tardar varios minutos dependiendo de tu internet)..."
	docker exec $(OLLAMA_CONTAINER) ollama pull $(MODEL_NAME)

import-api:
	@echo "==> [Paso 1] Importando definición OpenAPI en ZAP..."
	curl -s "http://localhost:8081/JSON/openapi/action/importUrl/?url=$(OPENAPI_URL)&target=$(TARGET_URL)"

scan:
	@echo "==> [Paso 2] Ejecutando Active Scan sobre $(TARGET_URL)..."
	curl -s "http://localhost:8081/JSON/ascan/action/scan/?url=$(TARGET_URL)"

report:
	@echo "==> [Paso 3] Exportando hallazgos a JSON..."
	-mkdir -p $(REPORT_DIR) 2>nul || cd .
	curl -s "http://localhost:8081/OTHER/core/other/jsonreport/" > $(REPORT_DIR)/zap-report.json

remediate:
	@echo "==> [Paso 4] Analizando vulnerabilidades con Ollama ($(MODEL_NAME))..."
	python3 analyze_report.py

all: import-api scan report remediate
	@echo "==> Pipeline DevSecOps completado exitosamente."

clean:
	@echo "==> Limpiando reportes generados..."
	-python3 -c "import os; [os.remove(f) for f in ['docs/security/zap-report.json', 'docs/security/remediation-report.md'] if os.path.exists(f)]"

reset: clean
	@echo "==> Limpiando todo el entorno (contenedores y volúmenes)..."
	docker-compose down -v
