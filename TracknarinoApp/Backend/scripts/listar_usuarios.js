require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/User');

async function listarUsuarios() {
  try {
    console.log('🔄 Conectando a MongoDB...');
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Conectado a MongoDB\n');

    const usuarios = await User.find({});
    
    console.log(`📊 Total de usuarios: ${usuarios.length}\n`);
    
    if (usuarios.length === 0) {
      console.log('⚠️  No hay usuarios registrados');
    } else {
      usuarios.forEach((user, index) => {
        console.log(`${index + 1}. ${user.nombre}`);
        console.log(`   📧 Correo: ${user.correo}`);
        console.log(`   👤 Tipo: ${user.tipoUsuario}`);
        console.log(`   🏢 Empresa: ${user.empresa || 'N/A'}`);
        console.log(`   📱 Teléfono: ${user.telefono || 'N/A'}`);
        console.log('');
      });
    }

    await mongoose.disconnect();
    console.log('🔌 Desconectado de MongoDB');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

listarUsuarios();
