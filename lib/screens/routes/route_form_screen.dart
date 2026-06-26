import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/route.dart';
import '../../models/transport_unit.dart';
import '../../providers/data_provider.dart';

class RouteFormScreen extends StatefulWidget {
  final String cooperativeId;
  final TransportRoute? route;

  const RouteFormScreen({
    super.key,
    required this.cooperativeId,
    this.route,
  });

  @override
  State<RouteFormScreen> createState() => _RouteFormScreenState();
}

class _RouteFormScreenState extends State<RouteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _idController;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _fareController;
  late TextEditingController _originIdController;
  late TextEditingController _destinationIdController;
  final List<RouteStop> _stops = [];
  bool _isLoading = false;
  final MapController _mapController = MapController();
  LatLng _mapCenter = const LatLng(-0.1807, -78.4678); // Default to Quito
  LatLng? _currentPosition;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.route?.id ?? '');
    _nameController = TextEditingController(text: widget.route?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.route?.description ?? '');
    _fareController =
        TextEditingController(text: widget.route?.fare.toString() ?? '');
    _originIdController =
        TextEditingController(text: widget.route?.originId?.toString() ?? '1');
    _destinationIdController =
        TextEditingController(text: widget.route?.destinationId?.toString() ?? '2');

    if (widget.route != null) {
      _stops.addAll(widget.route!.stops);
      if (_stops.isNotEmpty) {
        _mapCenter = LatLng(_stops.last.latitude, _stops.last.longitude);
      }
    }
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    try {
      final position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _currentPosition = latLng;
        if (widget.route == null && _stops.isEmpty) {
          _mapCenter = latLng;
          _mapController.move(latLng, 13.0);
        }
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _fareController.dispose();
    _originIdController.dispose();
    _destinationIdController.dispose();
    super.dispose();
  }

  void _addStopAt(LatLng point) {
    showDialog(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        return AlertDialog(
          title: Text('Nombre de la Parada', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'Ej: Terminal Terrestre',
              labelText: 'Nombre',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  setState(() {
                    _stops.add(RouteStop(
                      name: nameController.text.trim(),
                      latitude: point.latitude,
                      longitude: point.longitude,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final dataProvider = context.read<DataProvider>();
    final fare = int.parse(_fareController.text.trim());
    final originId = int.tryParse(_originIdController.text.trim());
    final destinationId = int.tryParse(_destinationIdController.text.trim());

    if (widget.route == null) {
      await dataProvider.addRoute(
        id: _idController.text.trim(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        fare: fare,
        cooperativeId: widget.cooperativeId,
        originId: originId,
        destinationId: destinationId,
        stops: _stops,
      );
    } else {
      await dataProvider.updateRoute(
        id: widget.route!.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        fare: fare,
        cooperativeId: widget.cooperativeId,
        originId: originId,
        destinationId: destinationId,
        stops: _stops,
      );
    }

    if (!mounted) return;

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.route == null
            ? 'Ruta creada exitosamente'
            : 'Ruta actualizada exitosamente'),
        backgroundColor: Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDeleteRouteDialog(BuildContext context, DataProvider dataProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmar eliminación', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
            '¿Está seguro de eliminar la ruta "${widget.route!.name}"? Sus unidades dejarán de estar asignadas a esta ruta.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              dataProvider.deleteRoute(widget.route!.id);
              Navigator.of(ctx).pop(); // pop dialog
              Navigator.of(context).pop(); // pop RouteFormScreen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ruta eliminada')),
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

  void _showAssignUnitDialog(BuildContext context, DataProvider dataProvider) {
    final allUnits = dataProvider.getUnitsByCooperative(widget.cooperativeId);
    final assignableUnits = allUnits.where((u) => u.routeId != widget.route?.id).toList();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            'Asignar Unidad a Ruta',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SizedBox(
            width: double.maxFinite,
            child: assignableUnits.isEmpty
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bus_alert_rounded, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No hay otras unidades en la cooperativa para asignar.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: Colors.grey.shade600),
                      ),
                    ],
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: assignableUnits.length,
                    itemBuilder: (context, index) {
                      final unit = assignableUnits[index];
                      final currentRouteName = unit.routeId != null
                          ? dataProvider.routes.firstWhere(
                              (r) => r.id == unit.routeId,
                              orElse: () => widget.route!, // fallback
                            ).name
                          : 'Ninguna';

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange.shade100,
                          child: Icon(Icons.directions_bus, color: Colors.orange.shade800),
                        ),
                        title: Text('Unidad ${unit.unitNumber}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                        subtitle: Text('Placa: ${unit.plate}\nRuta actual: $currentRouteName'),
                        onTap: () {
                          dataProvider.assignRouteToUnit(unit.id, widget.route!.id);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Unidad ${unit.unitNumber} asignada a la ruta')),
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
    final dataProvider = Provider.of<DataProvider>(context);
    final isEditing = widget.route != null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar Ruta' : 'Nueva Ruta',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: Colors.green.shade700,
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildSectionTitle('Información General', Icons.info_outline),
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
                              controller: _idController,
                              label: 'Número de Ruta (Ej: RUT-001)',
                              icon: Icons.numbers,
                              enabled: !isEditing,
                              validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _nameController,
                              label: 'Nombre de la Ruta',
                              icon: Icons.route,
                              validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _descriptionController,
                              label: 'Descripción de la Ruta',
                              icon: Icons.description_outlined,
                              validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _fareController,
                              label: 'Tarifa (Ej: 50)',
                              icon: Icons.attach_money,
                              validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _originIdController,
                                    label: 'ID Control Origen',
                                    icon: Icons.location_on,
                                    validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _destinationIdController,
                                    label: 'ID Control Destino',
                                    icon: Icons.flag,
                                    validator: (v) => v?.isEmpty ?? true ? 'Campo requerido' : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Paradas de la Ruta', Icons.map_outlined),
                    const SizedBox(height: 8),
                    Text(
                      'Toca el mapa para agregar una parada',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 300,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: _mapCenter,
                                initialZoom: 13.0,
                                onTap: (tapPosition, point) => _addStopAt(point),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.tesis.admin',
                                ),
                                MarkerLayer(
                                  markers: [
                                    if (_currentPosition != null)
                                      Marker(
                                        point: _currentPosition!,
                                        width: 40,
                                        height: 40,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.3),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.blue, width: 2),
                                          ),
                                          child: const Center(
                                            child: Icon(Icons.my_location, color: Colors.blue, size: 20),
                                          ),
                                        ),
                                      ),
                                    ..._stops.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final stop = entry.value;
                                      return Marker(
                                        point: LatLng(stop.latitude, stop.longitude),
                                        width: 80,
                                        height: 80,
                                        child: Column(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(4),
                                                boxShadow: const [BoxShadow(blurRadius: 2, color: Colors.black26)],
                                              ),
                                              child: Text(
                                                '${index + 1}. ${stop.name}',
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const Icon(Icons.location_on, color: Colors.red, size: 30),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ],
                            ),
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: FloatingActionButton.small(
                                onPressed: _getCurrentLocation,
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.blue.shade700,
                                child: const Icon(Icons.my_location),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_stops.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.add_location_alt_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text('Aún no has agregado paradas', style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _stops.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final stop = _stops[index];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade100,
                                child: Text('${index + 1}', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                              ),
                              title: Text(stop.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                              subtitle: Text(
                                '${stop.latitude.toStringAsFixed(4)}, ${stop.longitude.toStringAsFixed(4)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => setState(() => _stops.removeAt(index)),
                              ),
                            ),
                          );
                        },
                      ),
                    if (isEditing) ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSectionTitle('Unidades Asignadas', Icons.directions_bus_outlined),
                          TextButton.icon(
                            onPressed: () => _showAssignUnitDialog(context, dataProvider),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Asignar'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Builder(
                        builder: (context) {
                          final List<TransportUnit> routeUnits = dataProvider.getUnitsByRoute(widget.route!.id);
                          if (routeUnits.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.directions_bus_outlined, size: 40, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No hay unidades asignadas a esta ruta',
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                                  ),
                                ],
                              ),
                            );
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: routeUnits.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final unit = routeUnits[index];
                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey.shade200),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.orange.shade100,
                                    child: Icon(Icons.directions_bus, color: Colors.orange.shade800),
                                  ),
                                  title: Text(
                                    'Unidad ${unit.unitNumber}',
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Text('Placa: ${unit.plate}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.link_off, color: Colors.red),
                                    tooltip: 'Desasignar',
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: Text('Confirmar desasignación', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                          content: Text('¿Está seguro de quitar la unidad "${unit.unitNumber}" de esta ruta?'),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(ctx).pop(),
                                              child: const Text('Cancelar'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                dataProvider.assignRouteToUnit(unit.id, null);
                                                Navigator.of(ctx).pop();
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Unidad desasignada de la ruta')),
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
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        minimumSize: const Size(double.infinity, 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(
                              isEditing ? 'Guardar Cambios' : 'Crear Ruta',
                              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                    if (isEditing) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : () => _showDeleteRouteDialog(context, dataProvider),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(
                          'Eliminar Ruta',
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
                    const SizedBox(height: 32),
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
        Icon(icon, color: Colors.green.shade700, size: 20),
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
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 22, color: Colors.green.shade700),
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
          borderSide: BorderSide(color: Colors.green.shade700, width: 2),
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
