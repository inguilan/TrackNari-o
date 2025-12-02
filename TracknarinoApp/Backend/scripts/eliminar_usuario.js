require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/User');

// Obtener el correo desde los argumentos de línea de comandos
const correo = process.argv[2];

if (!correo) {
  console.error('❌ Debes proporcionar un correo electrónico');
  console.log('Uso: node eliminar_usuario.js correo@example.com');
  process.exit(1);
}

async function eliminarUsuario() {
  try {
    console.log('🔄 Conectando a MongoDB...');
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Conectado a MongoDB\n');

    // Buscar el usuario
    const usuario = await User.findOne({ correo });
    
    if (!usuario) {
      console.log(`⚠️  No se encontró ningún usuario con el correo: ${correo}`);
      await mongoose.disconnect();
      process.exit(0);
    }

    console.log('👤 Usuario encontrado:');
    console.log(`   - Nombre: ${usuario.nombre}`);
    console.log(`   - Correo: ${usuario.correo}`);
    console.log(`   - Tipo: ${usuario.tipoUsuario}`);
    console.log(`   - Empresa: ${usuario.empresa || 'N/A'}\n`);

    // Eliminar el usuario
    await User.deleteOne({ correo });
    console.log('✅ Usuario eliminado exitosamente\n');

    await mongoose.disconnect();
    console.log('🔌 Desconectado de MongoDB');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

eliminarUsuario();
