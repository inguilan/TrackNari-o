import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/oportunidad_service.dart';

class CrearOportunidadScreen extends StatefulWidget {
  final VoidCallback? onOportunidadCreada;
  
  const CrearOportunidadScreen({
    super.key,
    this.onOportunidadCreada,
  });

  @override
  State<CrearOportunidadScreen> createState() => _CrearOportunidadScreenState();
}

class _CrearOportunidadScreenState extends State<CrearOportunidadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _origenController = TextEditingController();
  final _destinoController = TextEditingController();
  final _precioController = TextEditingController();
  final _pesoCargaController = TextEditingController();
  final _tipoCargaController = TextEditingController();
  final _direccionCargueController = TextEditingController();
  final _direccionDescargueController = TextEditingController();
  final _requisitosController = TextEditingController();
  
  DateTime _fechaSeleccionada = DateTime.now().add(const Duration(days: 1));
  bool _isLoading = false;
  String _errorMessage = '';
  
  @override
  void initState() {
    super.initState();
    // Llenar con datos de ejemplo para facilitar pruebas
    _tituloController.text = "Transporte de productos agrícolas";
    _descripcionController.text = "Se requiere transportar productos agrícolas frescos";
    _origenController.text = "Pasto";
    _destinoController.text = "Cali";
    _precioController.text = "800000";
    _pesoCargaController.text = "5";
    _tipoCargaController.text = "Productos agrícolas";
    _direccionCargueController.text = "Calle 20 # 15-30, Centro, Pasto";
    _direccionDescargueController.text = "Carrera 15 # 45-12, Norte, Cali";
  }
  
  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _origenController.dispose();
    _destinoController.dispose();
    _precioController.dispose();
    _pesoCargaController.dispose();
    _tipoCargaController.dispose();
    _direccionCargueController.dispose();
    _direccionDescargueController.dispose();
    _requisitosController.dispose();
    super.dispose();
  }
  
  Future<void> _mostrarSelectorFecha() async {
    final fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (fechaSeleccionada != null) {
      final horaSeleccionada = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_fechaSeleccionada),
      );
      
      if (horaSeleccionada != null) {
        setState(() {
          _fechaSeleccionada = DateTime(
            fechaSeleccionada.year,
            fechaSeleccionada.month,
            fechaSeleccionada.day,
            horaSeleccionada.hour,
            horaSeleccionada.minute,
          );
        });
      }
    }
  }
  
  Future<void> _crearOportunidad() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      try {
        final double? precioParsed = double.tryParse(_precioController.text.replaceAll(',', ''));
        final int? pesoCargaParsed = int.tryParse(_pesoCargaController.text);
        
        if (precioParsed == null || pesoCargaParsed == null) {
          throw Exception('Precio o peso de carga inválido');
        }
        
        // Crear un objeto completo con todos los campos necesarios
        final data = {
          'titulo': _tituloController.text.trim(),
          'descripcion': _descripcionController.text.trim(),
          'origen': _origenController.text.trim(),
          'destino': _destinoController.text.trim(),
          'direccionCargue': _direccionCargueController.text.trim(),
          'direccionDescargue': _direccionDescargueController.text.trim(),
          'fecha': _fechaSeleccionada.toIso8601String(),
          'precio': precioParsed,
          'pesoCarga': pesoCargaParsed,
          'tipoCarga': _tipoCargaController.text.trim(),
          'requisitosEspeciales': _requisitosController.text.isEmpty ? null : _requisitosController.text.trim(),
          'estado': 'disponible',
          'finalizada': false,
        };
        
        print('📤 Enviando datos de oportunidad: $data');
        
        final oportunidad = await OportunidadService.crearOportunidadCompleta(data);
        
        if (oportunidad != null && mounted) {
          print('✅ Oportunidad creada exitosamente: ${oportunidad.id}');
          
          // Limpiar formulario
          _tituloController.clear();
          _descripcionController.clear();
          _origenController.clear();
          _destinoController.clear();
          _direccionCargueController.clear();
          _direccionDescargueController.clear();
          _precioController.clear();
          _pesoCargaController.clear();
          _tipoCargaController.clear();
          _requisitosController.clear();
          _fechaSeleccionada = DateTime.now();
          
          setState(() {
            _isLoading = false;
          });
          
          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Oportunidad creada correctamente',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          
          // Llamar al callback si existe
          if (widget.onOportunidadCreada != null) {
            widget.onOportunidadCreada!();
          }
          
          // Pequeña espera para que se vea el mensaje
          await Future.delayed(const Duration(milliseconds: 500));
          
        } else {
          setState(() {
            _errorMessage = 'Error al crear la oportunidad';
            _isLoading = false;
          });
        }
      } catch (e) {
        print('❌ Error al crear oportunidad: $e');
        if (mounted) {
          setState(() {
            _errorMessage = 'Error: ${e.toString()}';
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Error al crear la oportunidad',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Oportunidad'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mensaje de error si existe
                    if (_errorMessage.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.red.shade800),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    
                    // Título
                    TextFormField(
                      controller: _tituloController,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        hintText: 'Ej: Transporte de mercancía a Pasto',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un título';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Descripción
                    TextFormField(
                      controller: _descripcionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        hintText: 'Detalles adicionales de la carga',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese una descripción';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Tipo de carga
                    TextFormField(
                      controller: _tipoCargaController,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de carga',
                        hintText: 'Ej: Alimentos, muebles, materiales',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el tipo de carga';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Peso de carga
                    TextFormField(
                      controller: _pesoCargaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Peso de la carga (toneladas)',
                        hintText: 'Ej: 5',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el peso';
                        }
                        try {
                          int.parse(value);
                        } catch (_) {
                          return 'Ingrese un valor numérico válido';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Origen
                    TextFormField(
                      controller: _origenController,
                      decoration: const InputDecoration(
                        labelText: 'Ciudad de origen',
                        hintText: 'Ciudad de origen',
                        prefixIcon: Icon(Icons.location_on_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese la ciudad de origen';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Dirección de cargue
                    TextFormField(
                      controller: _direccionCargueController,
                      decoration: const InputDecoration(
                        labelText: 'Dirección exacta de cargue',
                        hintText: 'Dirección completa para recoger',
                        prefixIcon: Icon(Icons.home_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese la dirección de cargue';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Destino
                    TextFormField(
                      controller: _destinoController,
                      decoration: const InputDecoration(
                        labelText: 'Ciudad de destino',
                        hintText: 'Ciudad de destino',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese la ciudad de destino';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Dirección de descargue
                    TextFormField(
                      controller: _direccionDescargueController,
                      decoration: const InputDecoration(
                        labelText: 'Dirección exacta de descargue',
                        hintText: 'Dirección completa para entregar',
                        prefixIcon: Icon(Icons.home),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese la dirección de descargue';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Requisitos especiales
                    TextFormField(
                      controller: _requisitosController,
                      decoration: const InputDecoration(
                        labelText: 'Requisitos especiales (opcional)',
                        hintText: 'Ej: Refrigeración, carga frágil',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Fecha
                    InkWell(
                      onTap: _mostrarSelectorFecha,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Fecha de entrega',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(_fechaSeleccionada),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Precio
                    TextFormField(
                      controller: _precioController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Precio (COP)',
                        hintText: 'Valor a pagar al transportador',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese el precio';
                        }
                        try {
                          double.parse(value.replaceAll(',', ''));
                        } catch (_) {
                          return 'Ingrese un valor numérico válido';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Botón para crear oportunidad
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _crearOportunidad,
                      child: const Text('CREAR OPORTUNIDAD'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 