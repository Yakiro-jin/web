import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/transport_unit.dart';
import '../../models/driver.dart';
import '../../providers/data_provider.dart';

class TransportUnitFormScreen extends StatefulWidget {
  final String cooperativeId;
  final TransportUnit? unit;

  const TransportUnitFormScreen({
    super.key,
    required this.cooperativeId,
    this.unit,
  });

  @override
  State<TransportUnitFormScreen> createState() =>
      _TransportUnitFormScreenState();
}

class _TransportUnitFormScreenState extends State<TransportUnitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _plateController;
  late TextEditingController _modelController;
  late TextEditingController _colorController;
  late TextEditingController _yearController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _plateController = TextEditingController(text: widget.unit?.plate ?? '');
    _modelController = TextEditingController(text: widget.unit?.model ?? '');
    _colorController = TextEditingController(text: widget.unit?.color ?? '');
    
    String initialYear = '';
    if (widget.unit != null && widget.unit!.yearOfManufacture.isNotEmpty) {
      try {
        final parsed = DateTime.parse(widget.unit!.yearOfManufacture);
        initialYear = parsed.year.toString();
      } catch (_) {
        initialYear = widget.unit!.yearOfManufacture;
      }
    }
    _yearController = TextEditingController(text: initialYear);
  }

  @override
  void dispose() {
    _plateController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final dataProvider = context.read<DataProvider>();
    
    // Format year as ISO date string: YYYY-01-01T00:00:00.000Z
    final yearVal = _yearController.text.trim();
    final isoDateStr = '$yearVal-01-01T00:00:00.000Z';

    if (widget.unit == null) {
      // Create new
      await dataProvider.addTransportUnit(
        plate: _plateController.text.trim(),
        model: _modelController.text.trim(),
        color: _colorController.text.trim(),
        yearOfManufacture: isoDateStr,
        cooperativeId: widget.cooperativeId,
      );
    } else {
      // Update existing
      await dataProvider.updateTransportUnit(
        id: widget.unit!.id,
        model: _modelController.text.trim(),
        color: _colorController.text.trim(),
        yearOfManufacture: isoDateStr,
        cooperativeId: widget.cooperativeId,
        routeId: widget.unit!.routeId,
        driverId: widget.unit!.driverId,
      );
    }

    if (!mounted) return;

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.unit == null
            ? 'Unidad creada exitosamente'
            : 'Unidad actualizada exitosamente'),
      ),
    );
  }

  // Muestra un diálogo de confirmación antes de eliminar el bus/unidad.
  // Llama a dataProvider.deleteTransportUnit y luego regresa a la pantalla anterior.
  void _showDeleteUnitDialog(BuildContext context, DataProvider dataProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmar eliminación', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('¿Está seguro de eliminar la unidad "${widget.unit!.plate}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              dataProvider.deleteTransportUnit(widget.unit!.id);
              Navigator.of(ctx).pop(); // Cierra el diálogo
              Navigator.of(context).pop(); // Cierra el formulario de edición
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Unidad eliminada')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // Muestra un diálogo con los choferes registrados en la cooperativa actual.
  // Permite al usuario seleccionar un chofer para asignarlo a esta unidad de transporte.
  void _showDriverSelectionDialog(BuildContext context, DataProvider dataProvider) {
    final drivers = dataProvider.getDriversByCooperative(widget.cooperativeId);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            'Asignar Chofer a Unidad ${widget.unit!.plate}',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SizedBox(
            width: double.maxFinite,
            child: drivers.isEmpty
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_off_rounded, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No hay choferes registrados en esta cooperativa.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.grey.shade600),
                      ),
                    ],
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: drivers.length,
                    itemBuilder: (context, index) {
                      final driver = drivers[index];
                      
                      // Buscamos la versión más actualizada de la unidad desde el dataProvider reactivo
                      final currentUnitState = dataProvider.units.firstWhere(
                        (u) => u.id == widget.unit!.id,
                        orElse: () => widget.unit!,
                      );
                      final isCurrent = currentUnitState.driverId == driver.id;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isCurrent ? Colors.green.shade100 : Colors.grey.shade100,
                          child: Icon(
                            Icons.person,
                            color: isCurrent ? Colors.green.shade800 : Colors.grey.shade700,
                          ),
                        ),
                        title: Text(
                          '${driver.name} ${driver.lastName}',
                          style: GoogleFonts.poppins(
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text('Telf: ${driver.phone}'),
                        trailing: isCurrent ? const Icon(Icons.check_circle, color: Colors.green) : null,
                        onTap: () {
                          // Asignamos el chofer a la unidad usando el provider
                          dataProvider.assignDriverToUnit(widget.unit!.id, driver.id);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Chofer ${driver.name} asignado')),
                          );
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obtenemos DataProvider de forma reactiva para actualizar la UI en cambios de asignación o borrado
    final dataProvider = Provider.of<DataProvider>(context);
    final isEditing = widget.unit != null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar Unidad' : 'Nueva Unidad',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(color: Colors.orange.shade700, height: 10),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionTitle('Detalles del Vehículo', Icons.directions_bus),
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
                            _buildTextField(
                              controller: _plateController,
                              label: 'Placa',
                              icon: Icons.badge,
                              enabled: !isEditing,
                              capitalization: TextCapitalization.characters,
                              validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _modelController,
                              label: 'Modelo (Ej: Toyota HiAce)',
                              icon: Icons.directions_car,
                              validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _colorController,
                              label: 'Color',
                              icon: Icons.color_lens_outlined,
                              validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _yearController,
                              label: 'Año de Fabricación (Ej: 2020)',
                              icon: Icons.calendar_today,
                              keyboardType: TextInputType.number,
                              formatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Campo requerido';
                                final n = int.tryParse(v);
                                if (n == null || n < 1900 || n > DateTime.now().year + 1) {
                                  return 'Ingrese un año válido';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Si estamos editando un bus/unidad existente, mostramos la sección para gestionar su chofer
                    if (isEditing) ...[
                      const SizedBox(height: 24),
                      // Fila de cabecera para la sección de Chofer Asignado
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle('Chofer Asignado', Icons.person_outline),
                          // Botón para asignar un chofer abriendo el diálogo de selección
                          TextButton.icon(
                            onPressed: () => _showDriverSelectionDialog(context, dataProvider),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Asignar'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Builder reactivo para consultar el estado del chofer asignado a esta unidad
                      Builder(
                        builder: (context) {
                          // Obtenemos el estado actual del bus desde la lista reactiva de unidades en el DataProvider
                          final currentUnit = dataProvider.units.firstWhere(
                            (u) => u.id == widget.unit!.id,
                            orElse: () => widget.unit!,
                          );
                          
                          // Si no hay un chofer asignado, mostramos una advertencia visual bonita
                          if (currentUnit.driverId == null || currentUnit.driverId!.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.person_off_outlined, size: 40, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Sin chofer asignado',
                                    style: TextStyle(color: Colors.red.shade400, fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            );
                          }

                          // Si hay un chofer, buscamos sus detalles en la lista de choferes del provider
                          final driver = dataProvider.drivers.firstWhere(
                            (d) => d.id == currentUnit.driverId,
                            orElse: () => Driver(
                              id: currentUnit.driverId!,
                              name: 'Chofer',
                              lastName: 'No Encontrado',
                              email: '',
                              phone: '',
                              age: 0,
                              cooperativeId: widget.cooperativeId,
                              createdAt: DateTime.now(),
                            ),
                          );

                          // Mostramos la tarjeta del chofer asignado con opción de quitarlo
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade100,
                                child: Icon(Icons.person, color: Colors.green.shade800),
                              ),
                              title: Text(
                                '${driver.name} ${driver.lastName}',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text('Telf: ${driver.phone}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.person_remove, color: Colors.red),
                                tooltip: 'Quitar Chofer',
                                onPressed: () {
                                  // Diálogo de confirmación antes de desasignar al chofer del bus
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text('Confirmar desasignación', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                      content: Text('¿Está seguro de quitar al chofer "${driver.name}" de esta unidad?'),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(ctx).pop(),
                                          child: const Text('Cancelar'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            // Desasignamos al chofer pasando null como driverId
                                            dataProvider.assignDriverToUnit(widget.unit!.id, null);
                                            Navigator.of(ctx).pop();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Chofer desasignado de la unidad')),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                          ),
                                          child: const Text('Quitar'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 32),
                    // Botón principal para Guardar/Actualizar los detalles del bus
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
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
                              isEditing ? 'Actualizar Unidad' : 'Crear Unidad',
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                    // Si estamos editando, mostramos el botón Eliminar en rojo al final de toda la pantalla
                    if (isEditing) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : () => _showDeleteUnitDialog(context, dataProvider),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(
                          'Eliminar Unidad',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          minimumSize: const Size(double.infinity, 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange.shade700, size: 20),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      textCapitalization: capitalization,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 22, color: Colors.orange.shade700),
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
          borderSide: BorderSide(color: Colors.orange.shade700, width: 2),
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
