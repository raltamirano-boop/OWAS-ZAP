.PHONY: help import-api scan generate-report remediate all clean reset

# Variables
OPENAPI_URL ?= http://host.docker.internal:8080/v3/api-docs
TARGET_URL ?= http://host.docker.internal:8080
ZAP_CONTAINER = zap
OLLAMA_CONTAINER = ollama-llm
MODEL_NAME ?= qwen2.5-coder:7b
REPORT_DIR = ./docs/security

help:
	@echo "Comandos disponibles:"
	@echo "  make import-api  - Importa la especificación OpenAPI en OWASP ZAP"
	@echo "  make scan        - Ejecuta el escaneo activo en OWASP ZAP"
	@echo "  make report      - Genera y exporta zap-report.json"
	@echo "  make remediate   - Procesa zap-report.json con Ollama y crea el reporte Markdown"
	@echo "  make all         - Ejecuta todo el flujo completo de DevSecOps"
	@echo "  make clean       - Elimina los reportes generados localmente"
	@echo "  make reset       - Elimina los reportes y baja los contenedores borrando sus volúmenes"

import-api:
	@echo "==> [Paso 1] Importando definición OpenAPI en ZAP..."
	docker exec $(ZAP_CONTAINER) zap-cli openapi import $(OPENAPI_URL) Target=$(TARGET_URL)

scan:
	@echo "==> [Paso 2] Ejecutando Active Scan sobre $(TARGET_URL)..."
	docker exec $(ZAP_CONTAINER) zap-cli active-scan $(TARGET_URL)

report:
	@echo "==> [Paso 3] Exportando hallazgos a JSON..."
	mkdir -p $(REPORT_DIR)
	docker exec $(ZAP_CONTAINER) zap-cli report -o /zap/wrk/zap-report.json -f json

remediate:
	@echo "==> [Paso 4] Analizando vulnerabilidades con Ollama ($(MODEL_NAME))..."
	python3 analyze_report.py

all: import-api scan report remediate
	@echo "==> Pipeline DevSecOps completado exitosamente."

clean:
	@echo "==> Limpiando reportes generados..."
	rm -f $(REPORT_DIR)/zap-report.json $(REPORT_DIR)/remediation-report.md

reset: clean
	@echo "==> Limpiando todo el entorno (contenedores y volúmenes)..."
	docker-compose down -v
