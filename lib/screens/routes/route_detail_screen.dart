import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/route.dart';
import '../../providers/data_provider.dart';
import '../../widgets/transport_unit_card.dart';
import '../units/transport_unit_form_screen.dart';

class RouteDetailScreen extends StatefulWidget {
  final TransportRoute route;

  const RouteDetailScreen({super.key, required this.route});

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAssignUnitDialog(BuildContext context, DataProvider dataProvider) {
    final allUnits = dataProvider.getUnitsByCooperative(widget.route.cooperativeId);
    final assignableUnits = allUnits.where((u) => u.routeId != widget.route.id).toList();

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
                              orElse: () => widget.route, // fallback
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
                          dataProvider.assignRouteToUnit(unit.id, widget.route.id);
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
    final stops = widget.route.stops;
    final center = stops.isNotEmpty 
      ? LatLng(stops.first.latitude, stops.first.longitude)
      : const LatLng(-0.1807, -78.4678);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          widget.route.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'DETALLES', icon: Icon(Icons.info_outline)),
            Tab(text: 'UNIDADES', icon: Icon(Icons.directions_bus)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Details and Map
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildInfoCard(),
                _buildMapSection(center, stops),
                _buildStopsList(stops),
                const SizedBox(height: 80),
              ],
            ),
          ),
          
          // Tab 2: Units List
          _buildUnitsTab(context),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAssignUnitDialog(context, context.read<DataProvider>());
        },
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Asignar Unidad'),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildDetailItem(Icons.location_on, 'Origen', widget.route.origin, Colors.green.shade700),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(),
            ),
            _buildDetailItem(Icons.flag, 'Destino', widget.route.destination, Colors.red.shade700),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapSection(LatLng center, List<RouteStop> stops) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recorrido de la Ruta',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: 12.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.tesis.admin',
                  ),
                  if (stops.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: stops.map((s) => LatLng(s.latitude, s.longitude)).toList(),
                          color: Colors.green.shade700,
                          strokeWidth: 4.0,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: stops.asMap().entries.map((entry) {
                      final index = entry.key;
                      final stop = entry.value;
                      return Marker(
                        point: LatLng(stop.latitude, stop.longitude),
                        width: 30,
                        height: 30,
                        child: Icon(
                          index == 0 ? Icons.location_on : (index == stops.length - 1 ? Icons.flag : Icons.circle),
                          color: index == 0 ? Colors.green : (index == stops.length - 1 ? Colors.red : Colors.orange),
                          size: 30,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopsList(List<RouteStop> stops) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paradas (${stops.length})',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (stops.isEmpty)
            Text('No hay paradas registradas para esta ruta.', style: TextStyle(color: Colors.grey.shade600))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stops.length,
              itemBuilder: (context, index) {
                final stop = stops[index];
                return IntrinsicHeight(
                  child: Row(
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: index == 0 ? Colors.green : (index == stops.length - 1 ? Colors.red : Colors.orange),
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (index != stops.length - 1)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: Colors.grey.shade300,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(stop.name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
                              Text(
                                '${stop.latitude.toStringAsFixed(6)}, ${stop.longitude.toStringAsFixed(6)}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildUnitsTab(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final units = dataProvider.getUnitsByRoute(widget.route.id);

        if (units.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_bus_outlined, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No hay unidades asignadas',
                  style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
                Text('Asigna una unidad con el botón +', style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: units.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final unit = units[index];
            final matchingDrivers = dataProvider.drivers.where((d) => d.id == unit.driverId);
            final driverName = matchingDrivers.isNotEmpty ? '${matchingDrivers.first.name} ${matchingDrivers.first.lastName}' : null;

            return TransportUnitCard(
              unit: unit,
              driverName: driverName,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TransportUnitFormScreen(
                      cooperativeId: widget.route.cooperativeId,
                      unit: unit,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
