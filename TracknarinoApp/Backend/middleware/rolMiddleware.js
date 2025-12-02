function soloRol(rol) {
  return (req, res, next) => {
    // Soportar tanto 'tipo' como 'tipoUsuario' en el token
    const rolUsuario = req.usuario.tipoUsuario || req.usuario.tipo;
    
    console.log(`Verificando rol: requerido=${rol}, actual=${rolUsuario}`);
    
    if (!rolUsuario) {
      console.log('Acceso denegado: No se encontró el rol del usuario en el token');
      return res.status(403).json({ 
        mensaje: 'Acceso denegado: Rol no encontrado en token'
      });
    }
    
    // Si se pasa un array de roles, verificar si el usuario tiene alguno de ellos
    if (Array.isArray(rol)) {
      if (!rol.includes(rolUsuario)) {
        console.log(`Acceso denegado: El usuario con rol ${rolUsuario} no tiene uno de los roles permitidos: ${rol.join(', ')}`);
        return res.status(403).json({ 
          mensaje: 'Acceso denegado: Rol insuficiente',
          rolesPermitidos: rol,
          rolActual: rolUsuario
        });
      }
    } else {
      // Si se pasa un solo rol, verificar si el usuario lo tiene
      if (rolUsuario !== rol) {
        console.log(`Acceso denegado: El usuario con rol ${rolUsuario} no tiene el rol requerido: ${rol}`);
        return res.status(403).json({ 
          mensaje: 'Acceso denegado: Rol insuficiente',
          rolRequerido: rol,
          rolActual: rolUsuario
        });
      }
    }
    
    console.log(`Usuario con rol ${rolUsuario} autorizado`);
    next();
  };
}

module.exports = soloRol;
