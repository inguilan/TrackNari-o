@echo off
REM Script para generar JWT_SECRET seguro en Windows
REM Uso: generar_jwt_secret.bat

echo.
echo 🔐 Generando JWT_SECRET seguro...
echo.

node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

echo.
echo 📝 Copia esta clave y úsala en:
echo    - Backend/.env (desarrollo)
echo    - Render Environment Variables (producción)
echo.
echo ⚠️  IMPORTANTE: Nunca compartas esta clave públicamente
echo.
pause
