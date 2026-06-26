import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/cooperative.dart';
import '../../providers/data_provider.dart';

class CooperativeFormScreen extends StatefulWidget {
  final Cooperative? cooperative; // Si es null, estamos creando; si tiene valor, estamos editando

  const CooperativeFormScreen({super.key, this.cooperative});

  @override
  State<CooperativeFormScreen> createState() => _CooperativeFormScreenState();
}

class _CooperativeFormScreenState extends State<CooperativeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controlador para los dígitos del RIF (sin el prefijo). Ejemplo: "12345678-9"
  late TextEditingController _rifDigitsController;

  // Controlador para el nombre de la cooperativa
  late TextEditingController _nameController;

  // Controlador para la descripción (ahora opcional)
  late TextEditingController _descriptionController;

  bool _isLoading = false;

  // ─── Estado del selector de tipo de RIF ───
  // Opciones de prefijo para el RIF empresarial venezolano
  // J = Jurídico, V = Persona natural venezolana, E = Extranjero, G = Gobierno
  static const List<String> _rifPrefixes = ['J', 'V', 'E', 'G'];
  late String _selectedRifPrefix;

  // ─── Estado del selector de municipio (ubicación) ───
  // Lista de los 11 municipios del Estado Nueva Esparta con sus capitales
  static const List<String> _municipios = [
    'Antolín del Campo - Plaza de Paraguachí',
    'Arismendi - La Asunción',
    'Antonio Díaz - San Juan Bautista',
    'García - El Valle del Espíritu Santo',
    'Gómez - Santa Ana',
    'Maneiro - Pampatar',
    'Marcano - Juan Griego',
    'Mariño - Porlamar',
    'Península de Macanao - Boca de Río',
    'Tubores - Punta de Piedras',
    'Villalba - San Pedro de Coche',
  ];
  String? _selectedMunicipio;

  // ─── Estado de los selectores de hora (horario) ───
  // Hora de inicio y fin del horario de la cooperativa
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();

    // Si estamos editando, extraemos los datos existentes de la cooperativa
    if (widget.cooperative != null) {
      final coop = widget.cooperative!;

      // Extraer el prefijo y los dígitos del RIF existente
      // El RIF tiene formato "J-12345678-9", así que separamos por el primer guion
      if (coop.id.isNotEmpty && coop.id.contains('-')) {
        _selectedRifPrefix = coop.id.substring(0, 1).toUpperCase();
        // Si el prefijo no está en la lista, usamos 'J' por defecto
        if (!_rifPrefixes.contains(_selectedRifPrefix)) {
          _selectedRifPrefix = 'J';
        }
        // Los dígitos son todo después del primer guion: "12345678-9"
        _rifDigitsController = TextEditingController(text: coop.id.substring(2));
      } else {
        _selectedRifPrefix = 'J';
        _rifDigitsController = TextEditingController(text: coop.id);
      }

      _nameController = TextEditingController(text: coop.name);
      _descriptionController = TextEditingController(text: coop.description);

      // Intentar encontrar el municipio en la lista de municipios disponibles
      _selectedMunicipio = _municipios.cast<String?>().firstWhere(
        (m) => m == coop.location,
        orElse: () => null,
      );

      // Parsear el horario existente con formato "HH:MM - HH:MM"
      _parseSchedule(coop.schedule);
    } else {
      // Valores por defecto para crear una nueva cooperativa
      _selectedRifPrefix = 'J';
      _rifDigitsController = TextEditingController();
      _nameController = TextEditingController();
      _descriptionController = TextEditingController();
      _selectedMunicipio = null;
      _startTime = null;
      _endTime = null;
    }
  }

  /// Parsea un string de horario con formato "HH:MM - HH:MM" y establece
  /// las variables _startTime y _endTime correspondientes.
  void _parseSchedule(String schedule) {
    if (schedule.contains('-')) {
      final parts = schedule.split('-').map((s) => s.trim()).toList();
      if (parts.length == 2) {
        _startTime = _parseTimeString(parts[0]);
        _endTime = _parseTimeString(parts[1]);
      }
    }
  }

  /// Convierte un string "HH:MM" en un objeto TimeOfDay.
  /// Retorna null si el formato no es válido.
  TimeOfDay? _parseTimeString(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour != null && minute != null) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }
    return null;
  }

  /// Formatea un TimeOfDay como string "HH:MM" con padding de ceros.
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  void dispose() {
    _rifDigitsController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Abre el selector nativo de hora del sistema operativo.
  /// [isStart] indica si estamos seleccionando la hora de inicio (true) o fin (false).
  Future<void> _pickTime(bool isStart) async {
    final initialTime = isStart
        ? (_startTime ?? const TimeOfDay(hour: 5, minute: 0))
        : (_endTime ?? const TimeOfDay(hour: 22, minute: 0));

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        // Aplicamos tema oscuro al selector de hora para consistencia visual
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF1A1F2B),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.grey.shade800,
            ),
          ),
          child: child!,
        );
      },
    );

    // Si el usuario seleccionó una hora (no canceló), actualizamos el estado
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  /// Ejecuta la lógica de guardado del formulario.
  /// Combina el prefijo RIF + dígitos, el municipio seleccionado y el horario formateado.
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar que se haya seleccionado un municipio
    if (_selectedMunicipio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un municipio')),
      );
      return;
    }

    // Validar que se hayan seleccionado ambas horas del horario
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione el horario de inicio y fin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final dataProvider = context.read<DataProvider>();

    // Construir el RIF completo combinando prefijo + guion + dígitos
    // Ejemplo: "J" + "-" + "12345678-9" = "J-12345678-9"
    final fullRif = '$_selectedRifPrefix-${_rifDigitsController.text.trim()}';

    // Construir el string de horario con formato "HH:MM - HH:MM"
    final schedule = '${_formatTime(_startTime!)} - ${_formatTime(_endTime!)}';

    if (widget.cooperative == null) {
      // Crear nueva cooperativa en la API y el estado local
      await dataProvider.addCooperative(
        id: fullRif,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _selectedMunicipio!,
        schedule: schedule,
      );
    } else {
      // Actualizar cooperativa existente
      await dataProvider.updateCooperative(
        id: widget.cooperative!.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _selectedMunicipio!,
        schedule: schedule,
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.cooperative == null
            ? 'Cooperativa creada exitosamente'
            : 'Cooperativa actualizada exitosamente'),
      ),
    );

    Navigator.of(context).pop(widget.cooperative == null ? fullRif : null);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.cooperative != null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar Cooperativa' : 'Nueva Cooperativa',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF1A1F2B),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Barra decorativa superior que conecta visualmente con el AppBar
            Container(color: const Color(0xFF1A1F2B), height: 10),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── SECCIÓN: Información de la Empresa ───
                    _buildSectionTitle('Información de la Empresa', Icons.business_rounded),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // ─── CAMPO: RIF de la Cooperativa ───
                            // Fila que combina un Dropdown para el tipo (J, V, E, G)
                            // y un TextField para los dígitos (12345678-9)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Dropdown del prefijo RIF (J = Jurídica, V = Venezolano, etc.)
                                SizedBox(
                                  width: 90,
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedRifPrefix,
                                    decoration: InputDecoration(
                                      labelText: 'Tipo',
                                      labelStyle: const TextStyle(fontSize: 13),
                                      prefixIcon: const Icon(Icons.badge_outlined, size: 20, color: Color(0xFF1A1F2B)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF1A1F2B), width: 2),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                                      filled: true,
                                      fillColor: isEditing ? Colors.grey.shade100 : Colors.white,
                                    ),
                                    // Deshabilitamos el selector si estamos editando (el RIF no cambia)
                                    onChanged: isEditing ? null : (value) {
                                      setState(() => _selectedRifPrefix = value!);
                                    },
                                    items: _rifPrefixes.map((prefix) {
                                      return DropdownMenuItem(
                                        value: prefix,
                                        child: Text(prefix, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      );
                                    }).toList(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Campo de texto para los dígitos del RIF (8 números + guion + 1 dígito)
                                Expanded(
                                  child: TextFormField(
                                    controller: _rifDigitsController,
                                    enabled: !isEditing, // No se puede cambiar el RIF al editar
                                    keyboardType: TextInputType.text,
                                    inputFormatters: [
                                      // Permitir solo dígitos y guion
                                      FilteringTextInputFormatter.allow(RegExp(r'[\d-]')),
                                    ],
                                    decoration: InputDecoration(
                                      labelText: 'Número RIF (12345678-9)',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF1A1F2B), width: 2),
                                      ),
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey.shade200),
                                      ),
                                      filled: true,
                                      fillColor: isEditing ? Colors.grey.shade100 : Colors.white,
                                    ),
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'Campo requerido';
                                      // Validar formato de dígitos: 8 números, guion, 1 número
                                      if (!RegExp(r'^\d{8}-\d$').hasMatch(v.trim())) {
                                        return 'Formato: 12345678-9';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // ─── CAMPO: Nombre de la Cooperativa ───
                            _buildTextField(
                              controller: _nameController,
                              label: 'Nombre de la Cooperativa',
                              icon: Icons.business,
                              validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
                            ),
                            const SizedBox(height: 16),

                            // ─── CAMPO: Ubicación (Selector de Municipio) ───
                            // Dropdown con los 11 municipios del Estado Nueva Esparta
                            DropdownButtonFormField<String>(
                              value: _selectedMunicipio,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Municipio / Ubicación',
                                prefixIcon: const Icon(Icons.location_on_outlined, size: 22, color: Color(0xFF1A1F2B)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF1A1F2B), width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              // Al seleccionar un municipio, actualizamos el estado
                              onChanged: (value) {
                                setState(() => _selectedMunicipio = value);
                              },
                              validator: (v) => v == null ? 'Seleccione un municipio' : null,
                              items: _municipios.map((municipio) {
                                return DropdownMenuItem(
                                  value: municipio,
                                  child: Text(
                                    municipio,
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),

                            // ─── CAMPO: Horario (Selectores de Hora Inicio y Fin) ───
                            // Fila con dos botones que abren el picker de hora nativo
                            Row(
                              children: [
                                // Botón para seleccionar la hora de INICIO
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _pickTime(true),
                                    borderRadius: BorderRadius.circular(12),
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Hora Inicio',
                                        prefixIcon: const Icon(Icons.access_time, size: 22, color: Color(0xFF1A1F2B)),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                      child: Text(
                                        _startTime != null
                                            ? _formatTime(_startTime!)
                                            : 'Seleccionar',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: _startTime != null
                                              ? Colors.grey.shade800
                                              : Colors.grey.shade500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Botón para seleccionar la hora de FIN
                                Expanded(
                                  child: InkWell(
                                    onTap: () => _pickTime(false),
                                    borderRadius: BorderRadius.circular(12),
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Hora Fin',
                                        prefixIcon: const Icon(Icons.access_time, size: 22, color: Color(0xFF1A1F2B)),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                      ),
                                      child: Text(
                                        _endTime != null
                                            ? _formatTime(_endTime!)
                                            : 'Seleccionar',
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: _endTime != null
                                              ? Colors.grey.shade800
                                              : Colors.grey.shade500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // ─── CAMPO: Descripción (OPCIONAL) ───
                            // Este campo no tiene validador, por lo que el usuario puede dejarlo vacío
                            _buildTextField(
                              controller: _descriptionController,
                              label: 'Descripción o Eslogan (Opcional)',
                              icon: Icons.description_outlined,
                              maxLines: 3,
                              // Sin validator = campo opcional
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ─── BOTÓN: Guardar / Crear Cooperativa ───
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1F2B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(
                              isEditing ? 'Guardar Cambios' : 'Crear Cooperativa',
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el título de una sección del formulario con un icono y texto estilizado.
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF1A1F2B), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  /// Construye un campo de texto reutilizable con estilo consistente.
  /// [maxLines] permite campos multilínea (como la descripción).
  /// Si no se pasa [validator], el campo es opcional.
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 22, color: const Color(0xFF1A1F2B)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A1F2B), width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
      ),
    );
  }
}
