const User = require('../models/User');

// Afiliar camionero a contratista
const afiliarCamionero = async (req, res) => {
  try {
    const camioneroId = req.params.id;
    const contratistaId = req.usuario.id;

    // Verificar que el camionero existe y que no está ya afiliado
    const camionero = await User.findById(camioneroId);
    if (!camionero) {
      return res.status(404).json({ error: 'Camionero no encontrado' });
    }

    // Verificar si ya está afiliado
    if (camionero.camionerosAfiliados.includes(contratistaId)) {
      return res.status(400).json({ error: 'El camionero ya está afiliado a este contratista' });
    }

    // Afiliar camionero
    camionero.camionerosAfiliados.push(contratistaId);
    await camionero.save();

    res.json({ mensaje: 'Camionero afiliado correctamente', camionero });
  } catch (error) {
    res.status(500).json({ error: 'Error al afiliar al camionero' });
  }
};

// Rechazar afiliación de camionero
const rechazarAfiliacion = async (req, res) => {
  try {
    const camioneroId = req.params.id;
    const contratistaId = req.usuario.id;

    // Verificar que el camionero existe y que está afiliado
    const camionero = await User.findById(camioneroId);
    if (!camionero) {
      return res.status(404).json({ error: 'Camionero no encontrado' });
    }

    // Eliminar camionero de la lista de afiliados
    const index = camionero.camionerosAfiliados.indexOf(contratistaId);
    if (index > -1) {
      camionero.camionerosAfiliados.splice(index, 1);
      await camionero.save();
    }

    res.json({ mensaje: 'Afiliación rechazada', camionero });
  } catch (error) {
    res.status(500).json({ error: 'Error al rechazar la afiliación' });
  }
};

module.exports = {
  afiliarCamionero,
  rechazarAfiliacion
};
