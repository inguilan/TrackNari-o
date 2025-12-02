const mongoose = require('mongoose');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

// Conectar a MongoDB
const mongoUri = process.env.MONGO_URI || process.env.MONGODB_URI || 'mongodb://localhost:27017/trackarino';
console.log(`Conectando a: ${mongoUri}`);

mongoose.connect(mongoUri, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

const Oportunidad = require('../models/Oportunidad');

async function limpiarYCrearOportunidades() {
  try {
    console.log('🗑️  Eliminando todas las oportunidades anteriores...');
    await Oportunidad.deleteMany({});
    console.log('✅ Oportunidades eliminadas');

    console.log('\n📦 Creando nuevas oportunidades en Nariño...');

    // Oportunidades dentro del departamento de Nariño (distancias cortas)
    const oportunidadesNarino = [
      {
        titulo: 'Transporte de Café - Pasto a Ipiales',
        descripcion: 'Transporte de café empaquetado. Peso: 5000 kg. Ruta: Pasto → Ipiales (84 km)',
        origen: 'Pasto, Nariño',
        destino: 'Ipiales, Nariño',
        fecha: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000), // En 2 días
        precio: 450000,
        estado: 'disponible',
        finalizada: false,
        contratista: new mongoose.Types.ObjectId('692d161fc7e4c57265bc48df'),
      },
      {
        titulo: 'Productos Lácteos - Pasto a Túquerres',
        descripcion: 'Transporte de productos lácteos refrigerados. Peso: 3500 kg. Ruta: Pasto → Túquerres (59 km)',
        origen: 'Pasto, Nariño',
        destino: 'Túquerres, Nariño',
        fecha: new Date(Date.now() + 1 * 24 * 60 * 60 * 1000), // Mañana
        precio: 320000,
        estado: 'disponible',
        finalizada: false,
        contratista: new mongoose.Types.ObjectId('692d161fc7e4c57265bc48df'),
      },
      {
        titulo: 'Materiales de Construcción - Pasto a Samaniego',
        descripcion: 'Cemento y materiales de construcción. Peso: 8000 kg. Ruta: Pasto → Samaniego (95 km)',
        origen: 'Pasto, Nariño',
        destino: 'Samaniego, Nariño',
        fecha: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000), // En 3 días
        precio: 520000,
        estado: 'disponible',
        finalizada: false,
        contratista: new mongoose.Types.ObjectId('692d161fc7e4c57265bc48df'),
      },
      {
        titulo: 'Frutas Frescas - Pasto a Tumaco',
        descripcion: 'Transporte de frutas frescas. Peso: 4500 kg. Ruta: Pasto → Tumaco (304 km)',
        origen: 'Pasto, Nariño',
        destino: 'Tumaco, Nariño',
        fecha: new Date(Date.now() + 4 * 24 * 60 * 60 * 1000), // En 4 días
        precio: 980000,
        estado: 'disponible',
        finalizada: false,
        contratista: new mongoose.Types.ObjectId('692d161fc7e4c57265bc48df'),
      },
      {
        titulo: 'Suministros Agrícolas - Ipiales a Pasto',
        descripcion: 'Fertilizantes y suministros agrícolas. Peso: 6000 kg. Ruta: Ipiales → Pasto (84 km)',
        origen: 'Ipiales, Nariño',
        destino: 'Pasto, Nariño',
        fecha: new Date(Date.now() + 1 * 24 * 60 * 60 * 1000), // Mañana
        precio: 420000,
        estado: 'disponible',
        finalizada: false,
        contratista: new mongoose.Types.ObjectId('692d161fc7e4c57265bc48df'),
      },
      {
        titulo: 'Mercancía General - Túquerres a La Unión',
        descripcion: 'Mercancía general variada. Peso: 4000 kg. Ruta: Túquerres → La Unión (20 km)',
        origen: 'Túquerres, Nariño',
        destino: 'La Unión, Nariño',
        fecha: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000), // En 2 días
        precio: 180000,
        estado: 'disponible',
        finalizada: false,
        contratista: new mongoose.Types.ObjectId('692d161fc7e4c57265bc48df'),
      },
    ];

    const result = await Oportunidad.insertMany(oportunidadesNarino);
    
    console.log(`\n✅ ${result.length} oportunidades creadas exitosamente en Nariño:`);
    result.forEach((op, index) => {
      console.log(`\n${index + 1}. ${op.titulo}`);
      console.log(`   📍 ${op.origen} → ${op.destino}`);
      console.log(`   💰 $${op.precio.toLocaleString()}`);
      console.log(`   📅 ${op.fecha.toLocaleDateString()}`);
    });

    console.log('\n🎉 ¡Listo! Oportunidades de Nariño creadas.');
    
  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    mongoose.connection.close();
  }
}

limpiarYCrearOportunidades();
