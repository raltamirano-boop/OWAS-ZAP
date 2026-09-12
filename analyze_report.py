import json
import urllib.request
import urllib.error
import os

REPORT_PATH = './docs/security/zap-report.json'
OUTPUT_PATH = './docs/security/remediation-report.md'
OLLAMA_URL = 'http://localhost:11434/api/generate'
MODEL_NAME = 'qwen2.5-coder:7b'

SYSTEM_PROMPT = """
Eres un especialista en DevSecOps senior y un desarrollador experto en Java Spring Boot.
Tu trabajo es analizar una vulnerabilidad detectada por OWASP ZAP y devolver una solución precisa en formato Markdown.

Estructura obligatoria para la respuesta:
1. **Impacto Técnico y Riesgo**: Explicación concisa de por qué es peligrosa esta falla.
2. **Solución en Spring Boot**: Código Java exacto utilizando `SecurityFilterChain`, `HttpSecurity` o componentes necesarios.
3. **Configuración Alternativa**: Configuración en `application.yml`, Nginx o Spring Cloud Gateway si aplica.
"""

def load_zap_alerts(filepath):
    if not os.path.exists(filepath):
        print(f"Error: No se encontró el archivo {filepath}")
        return []
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    alerts = []
    site_data = data.get('site', [])
    if isinstance(site_data, dict):
        site_data = [site_data]
    
    for site in site_data:
        for alert in site.get('alerts', []):
            alerts.append({
                'name': alert.get('name'),
                'risk': alert.get('riskdesc'),
                'desc': alert.get('desc'),
                'url': alert.get('instances', [{}])[0].get('uri', alert.get('url', 'N/A')),
                'cweid': alert.get('cweid', 'N/A')
            })
    return alerts

def get_llm_fix(alert):
    prompt = f"""
    Vulnerabilidad: {alert['name']}
    Nivel de Riesgo: {alert['risk']}
    CWE ID: {alert['cweid']}
    URL Afectada: {alert['url']}
    Descripción OWASP: {alert['desc']}
    
    Proporciona el parche de código y la explicación técnica correspondiente.
    """
    
    payload = {
        "model": MODEL_NAME,
        "system": SYSTEM_PROMPT,
        "prompt": prompt,
        "stream": False,
        "options": {
            "temperature": 0.2
        }
    }
    
    data = json.dumps(payload).encode('utf-8')
    req = urllib.request.Request(OLLAMA_URL, data=data, headers={'Content-Type': 'application/json'})
    
    try:
        with urllib.request.urlopen(req, timeout=300) as response:
            if response.status == 200:
                result = json.loads(response.read().decode('utf-8'))
                return result.get('response', 'Sin respuesta del modelo.')
            else:
                return f"Error en Ollama (HTTP {response.status})"
    except urllib.error.URLError as e:
        return f"Error de conexión con Ollama: {str(e)}"
    except Exception as e:
        return f"Error inesperado al conectar con Ollama: {str(e)}"

def main():
    print("=== Iniciando Procesamiento Automático de Seguridad ===")
    alerts = load_zap_alerts(REPORT_PATH)
    
    if not alerts:
        print("No hay alertas para procesar.")
        return
    
    unique_alerts = {a['name']: a for a in alerts}.values()
    print(f"Total de alertas ZAP: {len(alerts)} | Únicas a procesar: {len(unique_alerts)}")
    
    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    
    with open(OUTPUT_PATH, 'w', encoding='utf-8') as out:
        out.write("# 🛡️ Reporte de Remediación Automática - DevSecOps\n\n")
        out.write(f"- **Microservicio:** `cac-service`\n")
        out.write(f"- **Motor de IA Local:** `{MODEL_NAME}` (Ollama)\n\n")
        out.write("---\n\n")
        
        for idx, alert in enumerate(unique_alerts, 1):
            print(f"[{idx}/{len(unique_alerts)}] Solicitando propuesta de código a Ollama para: {alert['name']}...")
            llm_solution = get_llm_fix(alert)
            
            out.write(f"## {idx}. {alert['name']}\n\n")
            out.write(f"| Atributo | Valor |\n")
            out.write(f"| :--- | :--- |\n")
            out.write(f"| **Riesgo** | `{alert['risk']}` |\n")
            out.write(f"| **CWE ID** | CWE-{alert['cweid']} |\n")
            out.write(f"| **Endpoint** | `{alert['url']}` |\n\n")
            out.write("### 💡 Propuesta de Remediación (Qwen2.5-Coder):\n\n")
            out.write(f"{llm_solution}\n\n")
            out.write("---\n\n")
            
    print(f"\n✅ Reporte de remediación generado exitosamente en: {OUTPUT_PATH}")

if __name__ == '__main__':
    main()
