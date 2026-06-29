import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/route.dart';

import '../../models/transport_unit.dart';

class RouteCard extends StatelessWidget {
  final TransportRoute route;
  final int unitCount;
  final List<TransportUnit> assignedUnits;
  final VoidCallback onTap;

  const RouteCard({
    super.key,
    required this.route,
    required this.unitCount,
    required this.assignedUnits,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.route,
                          color: Colors.green.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              route.name,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${route.origin} → ${route.destination}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildBadge(
                        Icons.directions_bus,
                        '$unitCount ${unitCount == 1 ? 'unidad' : 'unidades'}',
                        Colors.orange.shade700,
                        Colors.orange.shade50,
                      ),
                      _buildBadge(
                        Icons.location_on,
                        '${route.stops.length} paradas',
                        Colors.blue.shade700,
                        Colors.blue.shade50,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Listado de buses asignados
                  Row(
                    children: [
                      Icon(Icons.link, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          assignedUnits.isEmpty
                              ? 'Sin buses asignados'
                              : 'Buses: ${assignedUnits.map((u) => u.plate).join(', ')}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: assignedUnits.isEmpty
                                ? Colors.grey.shade500
                                : Colors.orange.shade800,
                            fontWeight: assignedUnits.isEmpty
                                ? FontWeight.normal
                                : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
