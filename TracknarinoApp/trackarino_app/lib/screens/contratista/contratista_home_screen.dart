import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/oportunidad_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/oportunidad_service.dart';
import 'crear_oportunidad_screen.dart';
import 'seguimiento_screen.dart';

class ContratistaHomeScreen extends StatefulWidget {
  final User usuario;

  const ContratistaHomeScreen({
    super.key,
    required this.usuario,
  });

  @override
  State<ContratistaHomeScreen> createState() => _ContratistaHomeScreenState();
}

class _ContratistaHomeScreenState extends State<ContratistaHomeScreen> {
  int _selectedIndex = 0;
  List<Oportunidad> _misOportunidades = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarOportunidades();
  }

  // Cargar oportunidades creadas por este contratista
  Future<void> _cargarOportunidades() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔄 Cargando oportunidades del contratista...');
      // Obtener todas las oportunidades disponibles
      final todasOportunidades = await OportunidadService.obtenerOportunidadesDisponibles();
      
      // Filtrar solo las del contratista actual
      _misOportunidades = todasOportunidades.where((op) {
        return op.contratista != null && op.contratista == widget.usuario.id;
      }).toList();
      
      print('✅ Oportunidades del contratista: ${_misOportunidades.length}');
    } catch (e) {
      print('❌ Error al cargar oportunidades: $e');
      _misOportunidades = [];
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Páginas del menú inferior
    final List<Widget> pages = [
      _buildHomePage(), // Dashboard principal
      _buildCrearOportunidadPage(), // Crear nueva oportunidad con callback
      const SeguimientoScreen(),
      _buildPerfilContratista(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracknariño - Contratista'),
        actions: [
          IconButton(
            onPressed: () async {
              await Provider.of<AuthService>(context, listen: false).logout();
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle),
            label: 'Crear',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Seguimiento',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0 
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _selectedIndex = 1; // Ir a la pestaña de crear oportunidad
                });
              },
              tooltip: 'Crear nueva oportunidad',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  // Construir la página principal con las tarjetas de información
  Widget _buildHomePage() {
    return RefreshIndicator(
      onRefresh: _cargarOportunidades,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con bienvenida
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.waving_hand,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '¡Bienvenido!',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.usuario.nombre,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.business, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          widget.usuario.empresa ?? 'Sin empresa',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Tarjetas de estadísticas rápidas
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.local_shipping,
                    label: 'Oportunidades',
                    value: '${_misOportunidades.length}',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.people,
                    label: 'Camioneros',
                    value: '${widget.usuario.camionerosAfiliados?.length ?? 0}',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Sección de Mis Oportunidades
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mis Oportunidades',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Crear'),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_misOportunidades.isEmpty)
              _buildEmptyOportunidades()
            else
              Column(
                children: _misOportunidades.take(5).map((oportunidad) {
                  return _buildOportunidadCard(oportunidad);
                }).toList(),
              ),
            
            const SizedBox(height: 24),
            
            // Acciones rápidas
            const Text(
              'Acciones Rápidas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 12),
            
            _buildQuickActionCard(
              icon: Icons.map,
              title: 'Seguimiento en tiempo real',
              subtitle: 'Ver la ubicación de tus camioneros',
              color: Colors.orange,
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
              },
            ),
            
            const SizedBox(height: 12),
            
            _buildQuickActionCard(
              icon: Icons.analytics,
              title: 'Reportes y estadísticas',
              subtitle: 'Próximamente disponible',
              color: Colors.purple,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Función próximamente disponible')),
                );
              },
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
  
  // Widget para tarjetas de estadísticas rápidas
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  // Widget para estado vacío de oportunidades
  Widget _buildEmptyOportunidades() {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes oportunidades',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primera oportunidad de transporte',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedIndex = 1;
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Crear Oportunidad'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget para tarjeta de oportunidad
  Widget _buildOportunidadCard(Oportunidad oportunidad) {
    final Color statusColor;
    switch (oportunidad.estado) {
      case 'disponible':
        statusColor = Colors.blue;
        break;
      case 'asignada':
        statusColor = Colors.orange;
        break;
      case 'en_ruta':
        statusColor = Colors.green;
        break;
      case 'finalizada':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.grey;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // TODO: Navegar a detalle
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      oportunidad.titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      oportunidad.estado,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${oportunidad.origen} → ${oportunidad.destino}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '\$${oportunidad.precio.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.scale, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${oportunidad.pesoCarga ?? 0}t',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Widget para tarjetas de acción rápida
  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  // Página para crear oportunidad con callback de actualización
  Widget _buildCrearOportunidadPage() {
    return WillPopScope(
      onWillPop: () async {
        print('🔄 WillPopScope: Volviendo y recargando oportunidades...');
        // Cuando se salga de la página de crear, recargar oportunidades
        await _cargarOportunidades();
        setState(() {
          _selectedIndex = 0; // Volver a home
        });
        return true;
      },
      child: CrearOportunidadScreen(
        onOportunidadCreada: () async {
          print('🎉 Callback: Oportunidad creada, recargando...');
          await _cargarOportunidades();
          setState(() {
            _selectedIndex = 0; // Volver a home automáticamente
          });
        },
      ),
    );
  }

  // Método para construir el perfil del contratista
  Widget _buildPerfilContratista() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header con gradiente y avatar
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.7),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                child: Column(
                  children: [
                    // Avatar con borde
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        child: Text(
                          widget.usuario.nombre.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Nombre
                    Text(
                      widget.usuario.nombre,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Tipo de usuario
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.business, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Contratista',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Información de la empresa
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Tarjeta de información de empresa
                _buildInfoCard(
                  icon: Icons.business_center,
                  title: 'Empresa',
                  value: widget.usuario.empresa ?? 'No especificada',
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                
                // Tarjeta de correo
                _buildInfoCard(
                  icon: Icons.email,
                  title: 'Correo electrónico',
                  value: widget.usuario.correo,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                
                // Tarjeta de teléfono
                if (widget.usuario.telefono != null)
                  _buildInfoCard(
                    icon: Icons.phone,
                    title: 'Teléfono',
                    value: widget.usuario.telefono!,
                    color: Colors.green,
                  ),
                if (widget.usuario.telefono != null)
                  const SizedBox(height: 16),
                
                // Estado de cuenta
                _buildInfoCard(
                  icon: Icons.verified_user,
                  title: 'Estado de aprobación',
                  value: widget.usuario.estadoAprobacion == 'aprobado'
                      ? 'Aprobado ✓'
                      : widget.usuario.estadoAprobacion == 'pendiente'
                          ? 'Pendiente'
                          : 'Rechazado',
                  color: widget.usuario.estadoAprobacion == 'aprobado'
                      ? Colors.green
                      : widget.usuario.estadoAprobacion == 'pendiente'
                          ? Colors.orange
                          : Colors.red,
                ),
                const SizedBox(height: 24),
                
                // Estadísticas
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.bar_chart, color: Colors.indigo),
                            SizedBox(width: 12),
                            Text(
                              'Estadísticas',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildStatRow('Oportunidades creadas', '${_misOportunidades.length}', Icons.add_task),
                        const Divider(height: 24),
                        _buildStatRow('Camioneros afiliados', '${widget.usuario.camionerosAfiliados?.length ?? 0}', Icons.people),
                        const Divider(height: 24),
                        _buildStatRow(
                          'Solicitar camioneros',
                          widget.usuario.disponibleParaSolicitarCamioneros == true ? 'Sí' : 'No',
                          Icons.local_shipping,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Botones de acción
                _buildActionButton(
                  icon: Icons.edit,
                  label: 'Editar perfil',
                  color: Colors.blue,
                  onTap: () {
                    _mostrarDialogoEditarPerfil();
                  },
                ),
                const SizedBox(height: 12),
                
                _buildActionButton(
                  icon: Icons.security,
                  label: 'Cambiar contraseña',
                  color: Colors.orange,
                  onTap: () {
                    _mostrarDialogoCambiarContrasena();
                  },
                ),
                const SizedBox(height: 12),
                
                _buildActionButton(
                  icon: Icons.logout,
                  label: 'Cerrar sesión',
                  color: Colors.red,
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Cerrar sesión'),
                        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('Cerrar sesión'),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirm == true && mounted) {
                      await Provider.of<AuthService>(context, listen: false).logout();
                    }
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Widget para tarjetas de información
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget para fila de estadísticas
  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  // Widget para botones de acción
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }
  
  // Diálogo para editar perfil
  void _mostrarDialogoEditarPerfil() {
    final nombreController = TextEditingController(text: widget.usuario.nombre);
    final telefonoController = TextEditingController(text: widget.usuario.telefono ?? '');
    final empresaController = TextEditingController(text: widget.usuario.empresa ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Perfil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: empresaController,
                decoration: const InputDecoration(
                  labelText: 'Empresa',
                  prefixIcon: Icon(Icons.business),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implementar actualización del perfil en el backend
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Perfil actualizado correctamente'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
  
  // Diálogo para cambiar contraseña
  void _mostrarDialogoCambiarContrasena() {
    final contrasenaActualController = TextEditingController();
    final contrasenaNuevaController = TextEditingController();
    final contrasenaConfirmarController = TextEditingController();
    bool _obscureActual = true;
    bool _obscureNueva = true;
    bool _obscureConfirmar = true;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Cambiar Contraseña'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: contrasenaActualController,
                  obscureText: _obscureActual,
                  decoration: InputDecoration(
                    labelText: 'Contraseña actual',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureActual ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setDialogState(() {
                          _obscureActual = !_obscureActual;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contrasenaNuevaController,
                  obscureText: _obscureNueva,
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNueva ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setDialogState(() {
                          _obscureNueva = !_obscureNueva;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contrasenaConfirmarController,
                  obscureText: _obscureConfirmar,
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmar ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setDialogState(() {
                          _obscureConfirmar = !_obscureConfirmar;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (contrasenaNuevaController.text != contrasenaConfirmarController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Las contraseñas no coinciden'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                if (contrasenaNuevaController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('La contraseña debe tener al menos 6 caracteres'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // TODO: Implementar cambio de contraseña en el backend
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Contraseña actualizada correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Cambiar'),
            ),
          ],
        ),
      ),
    );
  }
} 