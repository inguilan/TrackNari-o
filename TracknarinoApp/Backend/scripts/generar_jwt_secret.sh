#!/bin/bash

# Script para generar JWT_SECRET seguro
# Uso: bash generar_jwt_secret.sh

echo "🔐 Generando JWT_SECRET seguro...\n"

# Método 1: OpenSSL (si está disponible)
if command -v openssl &> /dev/null; then
    JWT_SECRET=$(openssl rand -hex 32)
    echo "✅ JWT_SECRET generado con OpenSSL:"
    echo "$JWT_SECRET"
    echo ""
else
    # Método 2: Node.js
    if command -v node &> /dev/null; then
        JWT_SECRET=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")
        echo "✅ JWT_SECRET generado con Node.js:"
        echo "$JWT_SECRET"
        echo ""
    else
        echo "❌ No se encontró ni OpenSSL ni Node.js"
        echo "Instala una de estas herramientas para generar claves seguras"
        exit 1
    fi
fi

echo "📝 Copia esta clave y úsala en:"
echo "   - Backend/.env (desarrollo)"
echo "   - Render Environment Variables (producción)"
echo ""
echo "⚠️  IMPORTANTE: Nunca compartas esta clave públicamente"
