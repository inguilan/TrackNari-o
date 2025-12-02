const mongoose = require('mongoose');
const Oportunidad = require('../models/Oportunidad');
const User = require('../models/User');
require('dotenv').config();

// Conectar a MongoDB
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('✅ Conectado a MongoDB'))
  .catch(err => {
    console.error('❌ Error al conectar a MongoDB:', err);
    process.exit(1);
  });

async function crearOportunidades() {
  try {
    // Buscar un contratista existente
    const contratista = await User.findOne({ tipoUsuario: 'contratista' });
    
    if (!contratista) {
      console.log('⚠️ No hay contratistas en la base de datos. Creando uno...');
      
      // Crear un contratista de prueba
      const bcrypt = require('bcrypt');
      const hashedPassword = await bcrypt.hash('password123', 10);
      
      const nuevoContratista = new User({
        nombre: 'Empresa Transportes S.A.',
        correo: 'contratista@test.com',
        contraseña: hashedPassword,
        telefono: '3001234567',
        tipoUsuario: 'contratista',
        empresaAfiliada: 'Transportes S.A.',
        empresa: 'Transportes S.A.'
      });
      
      await nuevoContratista.save();
      console.log('✅ Contratista creado');
    }

    const contratistaId = contratista ? contratista._id : (await User.findOne({ tipoUsuario: 'contratista' }))._id;

    // Limpiar oportunidades antiguas
    await Oportunidad.deleteMany({});
    console.log('🗑️ Oportunidades antiguas eliminadas');

    // Crear oportunidades de prueba realistas
    const oportunidades = [
      {
        contratista: contratistaId,
        titulo: 'Transporte de Alimentos Perecederos',
        origen: 'Pasto, Nariño',
        destino: 'Cali, Valle del Cauca',
        fecha: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000), // En 2 días
        precio: 1200000,
        descripcion: 'Transporte de frutas y verduras frescas. Requiere refrigeración. Peso: 8500 kg',
        estado: 'disponible'
      },
      {
        contratista: contratistaId,
        titulo: 'Carga desde Ipiales',
        origen: 'Ipiales, Nariño',
        destino: 'Bogotá, Cundinamarca',
        fecha: new Date(Date.now() + 1 * 24 * 60 * 60 * 1000), // Mañana
        precio: 2500000,
        descripcion: 'Carga seca, diversos productos importados desde Ecuador. Peso: 12000 kg',
        estado: 'disponible'
      },
      {
        contratista: contratistaId,
        titulo: 'Productos del Mar - URGENTE',
        origen: 'Tumaco, Nariño',
        destino: 'Pasto, Nariño',
        fecha: new Date(Date.now() + 12 * 60 * 60 * 1000), // En 12 horas
        precio: 800000,
        descripcion: 'Pescado fresco y mariscos. Transporte urgente con refrigeración. Peso: 5000 kg',
        estado: 'disponible'
      },
      {
        contratista: contratistaId,
        titulo: 'Materiales de Construcción',
        origen: 'Pasto, Nariño',
        destino: 'Popayán, Cauca',
        fecha: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000), // En 3 días
        precio: 950000,
        descripcion: 'Cemento, ladrillos y materiales varios para construcción. Peso: 15000 kg',
        estado: 'disponible'
      },
      {
        contratista: contratistaId,
        titulo: 'Productos Lácteos',
        origen: 'Pasto, Nariño',
        destino: 'Medellín, Antioquia',
        fecha: new Date(Date.now() + 4 * 24 * 60 * 60 * 1000), // En 4 días
        precio: 1800000,
        descripcion: 'Quesos, leche y derivados lácteos. Requiere refrigeración constante. Peso: 7000 kg',
        estado: 'disponible'
      }
    ];

    // Insertar oportunidades
    const resultado = await Oportunidad.insertMany(oportunidades);
    console.log(`✅ ${resultado.length} oportunidades creadas exitosamente`);

    // Mostrar resumen
    console.log('\n📋 Oportunidades creadas:');
    resultado.forEach((opp, index) => {
      console.log(`\n${index + 1}. ${opp.titulo}`);
      console.log(`   ${opp.origen} → ${opp.destino}`);
      console.log(`   Precio: $${opp.precio.toLocaleString('es-CO')}`);
      console.log(`   Fecha: ${opp.fecha.toLocaleDateString('es-CO')}`);
    });

    console.log('\n✅ Proceso completado');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error al crear oportunidades:', error);
    process.exit(1);
  }
}

crearOportunidades();
