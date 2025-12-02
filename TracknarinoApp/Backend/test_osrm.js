const axios = require('axios');
const polyline = require('@mapbox/polyline');

async function testOSRM() {
  try {
    // Ruta Pasto → Cali
    const origen = [-77.2886, 1.2053];  // Pasto [lng, lat]
    const destino = [-76.5305, 3.4372]; // Cali [lng, lat]
    
    const coordinates = `${origen[0]},${origen[1]};${destino[0]},${destino[1]}`;
    const url = `https://router.project-osrm.org/route/v1/driving/${coordinates}`;
    
    const params = {
      overview: 'full',
      geometries: 'polyline',
      steps: true,
    };

    console.log('🔍 Probando OSRM...');
    console.log(`URL: ${url}`);
    
    const response = await axios.get(url, { params });
    
    if (response.data && response.data.routes && response.data.routes.length > 0) {
      const route = response.data.routes[0];
      
      console.log('\n✅ Respuesta OSRM:');
      console.log(`- Código: ${response.data.code}`);
      console.log(`- Distancia: ${(route.distance / 1000).toFixed(2)} km`);
      console.log(`- Duración: ${Math.round(route.duration / 60)} minutos`);
      console.log(`- Geometría (polyline): ${route.geometry.substring(0, 50)}...`);
      
      // Decodificar polyline
      const decodedCoordinates = polyline.decode(route.geometry);
      console.log(`\n📍 Coordenadas decodificadas: ${decodedCoordinates.length} puntos`);
      
      // Convertir de [lat, lng] a [lng, lat]
      const coordinates_lnglat = decodedCoordinates.map(coord => [coord[1], coord[0]]);
      
      console.log('Primeros 5 puntos:');
      coordinates_lnglat.slice(0, 5).forEach((point, i) => {
        console.log(`  ${i + 1}. [${point[0].toFixed(6)}, ${point[1].toFixed(6)}]`);
      });
      
      console.log('...');
      console.log('Últimos 5 puntos:');
      coordinates_lnglat.slice(-5).forEach((point, i) => {
        console.log(`  ${coordinates_lnglat.length - 5 + i + 1}. [${point[0].toFixed(6)}, ${point[1].toFixed(6)}]`);
      });
      
      console.log('\n🎯 RESULTADO: ¡OSRM devuelve geometría detallada con múltiples puntos!');
      console.log(`   NO es una línea recta. Son ${decodedCoordinates.length} puntos siguiendo las carreteras reales.`);
    }
  } catch (error) {
    console.error('Error completo:', error);
    console.error('Mensaje:', error.message);
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', error.response.data);
    }
  }
}

testOSRM();
