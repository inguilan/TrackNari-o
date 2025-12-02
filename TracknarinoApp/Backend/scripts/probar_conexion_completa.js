require('dotenv').config();
const mongoose = require('mongoose');
const User = require('../models/User');
const Oportunidad = require('../models/Oportunidad');

async function probarConexionCompleta() {
  try {
    console.log('🔄 Conectando a MongoDB Atlas...');
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Conectado a MongoDB Atlas\n');

    // 1. Listar usuarios
    console.log('👥 USUARIOS REGISTRADOS:');
    const usuarios = await User.find({});
    console.log(`Total: ${usuarios.length}\n`);
    usuarios.forEach((user, i) => {
      console.log(`${i + 1}. ${user.nombre}`);
      console.log(`   📧 ${user.correo}`);
      console.log(`   👤 ${user.tipoUsuario}`);
      console.log('');
    });

    // 2. Listar oportunidades
    console.log('📦 OPORTUNIDADES DISPONIBLES:');
    const oportunidades = await Oportunidad.find({}).populate('contratista', 'nombre correo');
    console.log(`Total: ${oportunidades.length}\n`);
    oportunidades.forEach((op, i) => {
      console.log(`${i + 1}. ${op.titulo}`);
      console.log(`   📍 ${op.origen} → ${op.destino}`);
      console.log(`   💰 $${op.precio.toLocaleString()}`);
      console.log(`   📊 Estado: ${op.estado}`);
      console.log(`   👨‍💼 Contratista: ${op.contratista?.nombre || 'No asignado'}`);
      console.log('');
    });

    // 3. Verificar conexión del backend
    console.log('🔍 INFORMACIÓN DE LA BASE DE DATOS:');
    const db = mongoose.connection.db;
    const collections = await db.listCollections().toArray();
    console.log(`Colecciones activas: ${collections.length}`);
    collections.forEach(col => {
      console.log(`   - ${col.name}`);
    });

    await mongoose.disconnect();
    console.log('\n🔌 Desconectado de MongoDB');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

probarConexionCompleta();
