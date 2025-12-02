/**
 * Script para crear oportunidades de prueba en la base de datos
 * Uso: node crear_oportunidades_prueba.js
 */

require('dotenv').config();
const mongoose = require('mongoose');
const Oportunidad = require('../models/Oportunidad');
const User = require('../models/User');

// Datos de oportunidades realistas para Nariño
const oportunidadesPrueba = [
  {
    titulo: 'Transporte de café desde Consacá a Cali',
    descripcion: 'Se requiere transportar 8 toneladas de café premium desde Consacá hasta una bodega en Cali. Carga requiere cuidado especial.',
    origen: 'Consacá, Nariño',
    destino: 'Cali, Valle del Cauca',
    direccionCargue: 'Cooperativa de Caficultores, Calle 5 # 3-20, Consacá',
    direccionDescargue: 'Bodega Central, Calle 25 # 100-50, Cali',
    fecha: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000), // En 2 días
    precio: 1200000,
    pesoCarga: 8,
    tipoCarga: 'Café en sacos',
    requisitosEspeciales: 'Camión cubierto, evitar humedad',
    distanciaKm: 185,
    duracionEstimadaHoras: 4
  },
  {
    titulo: 'Carga de productos agrícolas Pasto - Bogotá',
    descripcion: 'Transporte de productos agrícolas frescos (papa, cebolla, arveja) desde Pasto hasta mercado mayorista en Bogotá.',
    origen: 'Pasto, Nariño',
    destino: 'Bogotá D.C.',
    direccionCargue: 'Central de Abastos, Carrera 27 # 18-50, Pasto',
    direccionDescargue: 'Corabastos, Avenida Las Americas, Bogotá',
    fecha: new Date(Date.now() + 1 * 24 * 60 * 60 * 1000), // Mañana
    precio: 2500000,
    pesoCarga: 15,
    tipoCarga: 'Productos agrícolas frescos',
    requisitosEspeciales: 'Transporte refrigerado preferible',
    distanciaKm: 820,
    duracionEstimadaHoras: 18
  },
  {
    titulo: 'Material de construcción Ipiales - Tumaco',
    descripcion: 'Transporte de materiales de construcción (cemento, hierro, arena) para proyecto de vivienda en Tumaco.',
    origen: 'Ipiales, Nariño',
    destino: 'Tumaco, Nariño',
    direccionCargue: 'Ferretería El Constructor, Carrera 5 # 14-30, Ipiales',
    direccionDescargue: 'Obra en construcción, Barrio Nuevo Milenio, Tumaco',
    fecha: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000), // En 3 días
    precio: 1800000,
    pesoCarga: 12,
    tipoCarga: 'Materiales de construcción',
    requisitosEspeciales: 'Camión con carpa, carga pesada',
    distanciaKm: 278,
    duracionEstimadaHoras: 8
  },
  {
    titulo: 'Productos lácteos Pupiales - Medellín',
    descripcion: 'Transporte urgente de productos lácteos (quesos, yogurt, leche) desde planta procesadora en Pupiales.',
    origen: 'Pupiales, Nariño',
    destino: 'Medellín, Antioquia',
    direccionCargue: 'Lácteos del Sur, Km 2 vía Gualmatán, Pupiales',
    direccionDescargue: 'Distribuidora Central, Calle 10 Sur # 50-30, Medellín',
    fecha: new Date(Date.now() + 12 * 60 * 60 * 1000), // En 12 horas (urgente)
    precio: 3200000,
    pesoCarga: 6,
    tipoCarga: 'Productos lácteos perecederos',
    requisitosEspeciales: 'URGENTE - Camión refrigerado obligatorio',
    distanciaKm: 920,
    duracionEstimadaHoras: 20
  },
  {
    titulo: 'Muebles artesanales Sandoná - Bucaramanga',
    descripcion: 'Transporte de muebles artesanales de madera desde talleres de Sandoná hasta tienda en Bucaramanga.',
    origen: 'Sandoná, Nariño',
    destino: 'Bucaramanga, Santander',
    direccionCargue: 'Taller Artesanal Los Maestros, Calle 6 # 4-15, Sandoná',
    direccionDescargue: 'Muebles Exclusivos, Carrera 27 # 45-20, Bucaramanga',
    fecha: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000), // En 5 días
    precio: 2000000,
    pesoCarga: 4,
    tipoCarga: 'Muebles artesanales de madera',
    requisitosEspeciales: 'Carga frágil, embalaje especial',
    distanciaKm: 850,
    duracionEstimadaHoras: 19
  },
  {
    titulo: 'Insumos agrícolas La Unión - Pasto',
    descripcion: 'Entrega de fertilizantes y semillas desde bodega regional hacia cooperativas agrícolas en Pasto.',
    origen: 'La Unión, Nariño',
    destino: 'Pasto, Nariño',
    direccionCargue: 'Agropecuaria La Esperanza, Carrera 3 # 7-40, La Unión',
    direccionDescargue: 'Cooperativa Multiactiva, Calle 18 # 25-10, Pasto',
    fecha: new Date(Date.now() + 1 * 24 * 60 * 60 * 1000), // Mañana
    precio: 450000,
    pesoCarga: 3,
    tipoCarga: 'Insumos agrícolas (fertilizantes y semillas)',
    requisitosEspeciales: 'Ninguno especial',
    distanciaKm: 78,
    duracionEstimadaHoras: 2
  }
];

async function crearOportunidadesPrueba() {
  try {
    // Conectar a MongoDB
    await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/trackarino', {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });
    console.log('✅ Conectado a MongoDB');

    // Buscar un usuario contratista existente
    let contratista = await User.findOne({ tipoUsuario: 'contratista' });
    
    if (!contratista) {
      console.log('⚠️  No hay contratistas registrados. Creando uno de prueba...');
      const bcrypt = require('bcrypt');
      const hash = await bcrypt.hash('123456', 10);
      
      contratista = new User({
        nombre: 'Transportes del Sur S.A.',
        correo: 'contratista@trackarino.com',
        contraseña: hash,
        tipoUsuario: 'contratista',
        telefono: '3001234567',
        empresa: 'Transportes del Sur S.A.',
        disponibleParaSolicitarCamioneros: true
      });
      
      await contratista.save();
      console.log('✅ Contratista de prueba creado');
    }

    console.log(`\n📦 Creando ${oportunidadesPrueba.length} oportunidades de prueba...\n`);

    // Limpiar oportunidades anteriores (opcional)
    const oportunidadesAnteriores = await Oportunidad.countDocuments();
    if (oportunidadesAnteriores > 0) {
      console.log(`⚠️  Hay ${oportunidadesAnteriores} oportunidades existentes.`);
      const readline = require('readline').createInterface({
        input: process.stdin,
        output: process.stdout
      });
      
      // En modo automático, no preguntar
      if (process.argv.includes('--auto')) {
        console.log('Modo automático: manteniendo oportunidades existentes\n');
      } else {
        await new Promise((resolve) => {
          readline.question('¿Deseas eliminarlas antes de crear las nuevas? (s/n): ', (respuesta) => {
            readline.close();
            if (respuesta.toLowerCase() === 's') {
              Oportunidad.deleteMany({}).then(() => {
                console.log('🗑️  Oportunidades anteriores eliminadas\n');
                resolve();
              });
            } else {
              console.log('Manteniendo oportunidades existentes\n');
              resolve();
            }
          });
        });
      }
    }

    // Crear cada oportunidad
    let creadas = 0;
    for (const oportunidadData of oportunidadesPrueba) {
      const oportunidad = new Oportunidad({
        ...oportunidadData,
        contratista: contratista._id,
        estado: 'disponible',
        finalizada: false
      });

      await oportunidad.save();
      creadas++;
      console.log(`✅ ${creadas}. ${oportunidad.titulo}`);
      console.log(`   ${oportunidad.origen} → ${oportunidad.destino}`);
      console.log(`   Precio: $${oportunidad.precio.toLocaleString('es-CO')} | Peso: ${oportunidad.pesoCarga}t | ${oportunidad.distanciaKm}km\n`);
    }

    console.log(`\n🎉 ¡${creadas} oportunidades creadas exitosamente!`);
    console.log(`\n📊 Estadísticas:`);
    console.log(`   - Total de oportunidades: ${await Oportunidad.countDocuments()}`);
    console.log(`   - Disponibles: ${await Oportunidad.countDocuments({ estado: 'disponible' })}`);
    console.log(`   - Usuario contratista: ${contratista.correo}`);
    console.log(`\n💡 Puedes iniciar sesión con:`);
    console.log(`   📧 Correo: ${contratista.correo}`);
    console.log(`   🔑 Contraseña: 123456\n`);

  } catch (error) {
    console.error('❌ Error al crear oportunidades:', error);
  } finally {
    await mongoose.connection.close();
    console.log('🔌 Desconectado de MongoDB');
  }
}

// Ejecutar
crearOportunidadesPrueba();
