#!/usr/bin/env node

/**
 * Script para probar la conexión a MongoDB Atlas
 * Uso: node probar_mongodb_atlas.js
 */

require('dotenv').config();
const mongoose = require('mongoose');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

console.log('🔍 Prueba de Conexión a MongoDB Atlas\n');

// Verificar si hay una URI en el .env
const uriEnv = process.env.MONGO_URI;

if (uriEnv && uriEnv.includes('mongodb+srv://')) {
  console.log('✅ URI encontrada en .env');
  probarConexion(uriEnv);
} else {
  console.log('⚠️  No se encontró URI de MongoDB Atlas en .env\n');
  rl.question('Pega tu MongoDB Atlas connection string aquí:\n', (uri) => {
    if (!uri || !uri.includes('mongodb+srv://')) {
      console.error('❌ URI inválida. Debe comenzar con mongodb+srv://');
      rl.close();
      process.exit(1);
    }
    probarConexion(uri);
  });
}

async function probarConexion(uri) {
  try {
    console.log('\n🔄 Intentando conectar a MongoDB Atlas...');
    console.log(`📍 URI: ${uri.replace(/\/\/([^:]+):([^@]+)@/, '//$1:****@')}\n`);

    await mongoose.connect(uri, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      serverSelectionTimeoutMS: 10000, // 10 segundos timeout
    });

    console.log('✅ ¡CONEXIÓN EXITOSA A MONGODB ATLAS!\n');

    // Obtener información del cluster
    const admin = mongoose.connection.db.admin();
    const info = await admin.serverInfo();
    
    console.log('📊 Información del Servidor:');
    console.log(`   - Versión: ${info.version}`);
    console.log(`   - Motor: ${info.storageEngine || 'N/A'}`);
    
    // Listar bases de datos
    const databases = await admin.listDatabases();
    console.log(`\n📁 Bases de datos disponibles:`);
    databases.databases.forEach(db => {
      console.log(`   - ${db.name} (${(db.sizeOnDisk / 1024 / 1024).toFixed(2)} MB)`);
    });

    // Listar colecciones en la base actual
    const collections = await mongoose.connection.db.listCollections().toArray();
    console.log(`\n📦 Colecciones en '${mongoose.connection.name}':`);
    if (collections.length === 0) {
      console.log('   (ninguna colección aún - es normal para una base nueva)');
    } else {
      collections.forEach(col => {
        console.log(`   - ${col.name}`);
      });
    }

    // Contar documentos si existe la colección de usuarios
    try {
      const User = mongoose.connection.collection('users');
      const userCount = await User.countDocuments();
      console.log(`\n👥 Total de usuarios: ${userCount}`);

      const Oportunidad = mongoose.connection.collection('oportunidads');
      const oportunidadCount = await Oportunidad.countDocuments();
      console.log(`📦 Total de oportunidades: ${oportunidadCount}`);
    } catch (e) {
      console.log('\n💡 Tip: Ejecuta crear_oportunidades_prueba.js para poblar la base de datos');
    }

    console.log('\n✨ La conexión está funcionando perfectamente.');
    console.log('📝 Puedes usar esta URI en Render para el despliegue.\n');

  } catch (error) {
    console.error('\n❌ ERROR AL CONECTAR A MONGODB ATLAS:\n');
    
    if (error.name === 'MongoServerSelectionError') {
      console.error('🔴 No se pudo conectar al servidor MongoDB Atlas.');
      console.error('\n🔧 Posibles soluciones:');
      console.error('   1. Verifica que la contraseña en la URI sea correcta');
      console.error('   2. Asegúrate de haber permitido acceso desde 0.0.0.0/0 en MongoDB Atlas');
      console.error('   3. Verifica que el cluster esté activo (no pausado)');
      console.error('   4. Revisa tu conexión a internet\n');
    } else if (error.name === 'MongoParseError') {
      console.error('🔴 La URI de conexión tiene un formato inválido.');
      console.error('\n📝 Formato correcto:');
      console.error('   mongodb+srv://usuario:password@cluster0.xxxxx.mongodb.net/nombre_db?retryWrites=true&w=majority\n');
    } else {
      console.error(`🔴 ${error.message}\n`);
    }

    console.error('Detalles técnicos:', error.name);
  } finally {
    await mongoose.connection.close();
    rl.close();
    process.exit(0);
  }
}
