const axios = require('axios');
const polyline = require('@mapbox/polyline');

/**
 * Servicio para calcular rutas usando OSRM (Open Source Routing Machine)
 * OSRM es más confiable y devuelve geometría real de carreteras
 */

// Configuración de OSRM - servidor público
const OSRM_BASE_URL = 'https://router.project-osrm.org/route/v1/driving';

/**
 * Obtiene la ruta óptima entre dos puntos usando OSRM
 * @param {Array} origen - [longitud, latitud] del punto de origen
 * @param {Array} destino - [longitud, latitud] del punto de destino
 * @returns {Object} Información de la ruta: coordinates, distancia, duración
 */
async function obtenerRutaORS(origen, destino) {
  try {
    // Validar coordenadas
    if (!Array.isArray(origen) || origen.length !== 2) {
      throw new Error('Origen debe ser un array [lng, lat]');
    }
    if (!Array.isArray(destino) || destino.length !== 2) {
      throw new Error('Destino debe ser un array [lng, lat]');
    }

    console.log(`🗺️  Calculando ruta OSRM: [${origen}] -> [${destino}]`);

    // OSRM usa formato: /route/v1/driving/lon1,lat1;lon2,lat2
    const coordinates = `${origen[0]},${origen[1]};${destino[0]},${destino[1]}`;
    const url = `${OSRM_BASE_URL}/${coordinates}`;
    
    // Añadir parámetros para obtener geometría completa
    const params = {
      overview: 'simplified',  // Usar geometría simplificada para ser más rápido
      geometries: 'polyline',  // Formato polyline (más compacto)
      steps: false,            // No incluir pasos detallados (más rápido)
      alternatives: false,     // Solo una ruta (la más corta)
      continue_straight: false, // Permitir giros para encontrar LA RUTA MÁS CORTA
      annotations: false,      // No incluir anotaciones extras
    };

    console.log(`📍 URL OSRM: ${url}`);

    const response = await axios.get(url, {
      params,
      timeout: 8000, // 8 segundos de timeout (más rápido)
    });

    if (!response.data) {
      throw new Error('OSRM no devolvió datos');
    }

    if (response.data.code !== 'Ok') {
      console.log('⚠️ OSRM error code:', response.data.code);
      throw new Error(`OSRM error: ${response.data.code}`);
    }

    if (!response.data.routes || response.data.routes.length === 0) {
      throw new Error('No se encontró una ruta válida en OSRM');
    }

    // Usar la primera ruta (ya no buscamos alternativas para ser más rápidos)
    const route = response.data.routes[0];
    
    console.log(`📊 Ruta encontrada: ${(route.distance / 1000).toFixed(2)} km`);
    
    // Decodificar la geometría polyline a coordenadas [lng, lat]
    const decodedCoordinates = polyline.decode(route.geometry);
    
    // OSRM devuelve [lat, lng], convertir a [lng, lat] para consistencia
    const coordinates_lnglat = decodedCoordinates.map(coord => [coord[1], coord[0]]);

    const resultado = {
      coordinates: coordinates_lnglat,
      distancia: (route.distance / 1000).toFixed(2), // Convertir metros a km
      duracion: Math.round(route.duration / 60), // Convertir segundos a minutos
      numeroDetalles: coordinates_lnglat.length, // Número de puntos en la ruta
    };

    console.log(`✅ Ruta OSRM calculada: ${resultado.distancia} km, ${resultado.duracion} min, ${resultado.numeroDetalles} puntos`);
    return resultado;

  } catch (error) {
    console.error('❌ Error al obtener ruta de OSRM:', error.message);

    // Si falla ORS, calcular distancia directa como fallback
    const distanciaDirecta = calcularDistanciaDirecta(origen, destino);
    const duracionEstimada = Math.round((distanciaDirecta / 60) * 60); // Asumiendo 60 km/h

    console.log(`⚠️  Usando ruta directa: ${distanciaDirecta.toFixed(2)} km`);

    return {
      coordinates: [origen, destino],
      distancia: distanciaDirecta.toFixed(2),
      duracion: duracionEstimada,
      fallback: true,
    };
  }
}

/**
 * Calcula la distancia directa entre dos puntos usando la fórmula de Haversine
 * @param {Array} punto1 - [longitud, latitud]
 * @param {Array} punto2 - [longitud, latitud]
 * @returns {Number} Distancia en kilómetros
 */
function calcularDistanciaDirecta(punto1, punto2) {
  const [lon1, lat1] = punto1;
  const [lon2, lat2] = punto2;

  const R = 6371; // Radio de la Tierra en km
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distancia = R * c;

  return distancia;
}

function toRad(valor) {
  return valor * Math.PI / 180;
}

module.exports = {
  obtenerRutaORS,
};
