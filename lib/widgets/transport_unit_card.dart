import 'package:flutter/material.dart';
import '../../models/transport_unit.dart';

class TransportUnitCard extends StatelessWidget {
  final TransportUnit unit; // Modelo de datos que representa la unidad de transporte
  final String? driverName; // Nombre completo del chofer asignado (puede ser nulo)
  final VoidCallback onTap; // Callback que se ejecuta al presionar la tarjeta completa

  const TransportUnitCard({
    super.key,
    required this.unit,
    this.driverName,
    required this.onTap, // onTap ahora es requerido para abrir la edición directamente
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap, // Acción al presionar directamente la tarjeta
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Icono representativo de autobús/unidad
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.directions_bus,
                  color: Colors.orange.shade700,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Información detallada de la unidad
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título principal con el modelo de la unidad
                    Text(
                      unit.model,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Fila con Placa y Color
                    Row(
                      children: [
                        Icon(Icons.badge, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            unit.plate,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.color_lens, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            unit.color,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Fila con el Chofer Asignado
                    Row(
                      children: [
                        Icon(Icons.person,
                            size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            (driverName != null && driverName!.isNotEmpty)
                                ? driverName!
                                : 'Sin chofer asignado',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: (driverName != null && driverName!.isNotEmpty)
                                  ? Colors.grey.shade800
                                  : Colors.red.shade400,
                              fontWeight: (driverName != null && driverName!.isNotEmpty)
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
