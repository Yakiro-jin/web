import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/cooperative.dart';
import '../models/route.dart';
import '../models/transport_unit.dart';
import '../models/driver.dart';

class ApiService {
  static final http.Client _client = http.Client();

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // --- COOPERATIVE ENDPOINTS ---

  static Future<List<Cooperative>> getCooperativas() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/cooperativa/cooperativas/todas');
    debugPrint('GET: $url');
    try {
      final response = await _client.get(url, headers: _headers);
      debugPrint('Status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((json) => Cooperative.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load cooperatives: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting cooperatives: $e');
      rethrow;
    }
  }

  static Future<Cooperative> createCooperativa(Cooperative cooperative) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/cooperativa/cooperativas/crear');
    debugPrint('POST: $url');
    final body = jsonEncode({
      'rif_cooperativa': cooperative.id,
      'nombre': cooperative.name,
      'descripcion': cooperative.description,
      'ubicacion': cooperative.location,
      'horario': cooperative.schedule,
    });
    debugPrint('Body: $body');
    try {
      final response = await _client.post(url, headers: _headers, body: body);
      debugPrint('Status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Cooperative.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create cooperative: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error creating cooperative: $e');
      rethrow;
    }
  }

  static Future<Cooperative> updateCooperativa(Cooperative cooperative) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/cooperativa/cooperativas/actualizar');
    debugPrint('PATCH: $url');
    final body = jsonEncode({
      'rif_cooperativa': cooperative.id,
      'nombre': cooperative.name,
      'descripcion': cooperative.description,
      'ubicacion': cooperative.location,
      'horario': cooperative.schedule,
    });
    debugPrint('Body: $body');
    try {
      final response = await _client.patch(url, headers: _headers, body: body);
      debugPrint('Status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200) {
        return Cooperative.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update cooperative: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating cooperative: $e');
      rethrow;
    }
  }

  static Future<void> deleteCooperativa(String rif) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/cooperativa/cooperativas/eliminar');
    debugPrint('DELETE: $url');
    final body = jsonEncode({'rif_cooperativa': rif});
    debugPrint('Body: $body');
    try {
      final response = await _client.delete(url, headers: _headers, body: body);
      debugPrint('Status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete cooperative: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting cooperative: $e');
      rethrow;
    }
  }

  // --- ROUTE (DESTINO) ENDPOINTS ---

  static Future<List<TransportRoute>> getRoutes() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rutas/destino/obtener');
    debugPrint('GET: $url');
    try {
      final response = await _client.get(url, headers: _headers);
      debugPrint('Status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((json) => TransportRoute.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load routes: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting routes: $e');
      rethrow;
    }
  }

  static Future<TransportRoute> createRoute(TransportRoute route) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rutas/destino/crear');
    debugPrint('POST: $url');
    final body = jsonEncode({
      'numero_ruta': route.id,
      'nombre': route.name,
      'descripcion': route.description,
      'tarifa': route.fare,
      'cooperativa_id': route.cooperativeId,
      'origen_id': route.originId,
      'destino_id': route.destinationId,
    });
    debugPrint('Body: $body');
    try {
      final response = await _client.post(url, headers: _headers, body: body);
      debugPrint('Status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return TransportRoute.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create route: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error creating route: $e');
      rethrow;
    }
  }

  static Future<TransportRoute> updateRoute(TransportRoute route) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/rutas/destino/actualizar');
    debugPrint('PATCH: $url');
    final body = jsonEncode({
      'numero_ruta': route.id,
      'nombre': route.name,
      'descripcion': route.description,
      'tarifa': route.fare,
      'cooperativa_id': route.cooperativeId,
      'origen_id': route.originId,
      'destino_id': route.destinationId,
    });
    debugPrint('Body: $body');
    try {
      final response = await _client.patch(url, headers: _headers, body: body);
      debugPrint('Status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200) {
        return TransportRoute.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update route: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating route: $e');
      rethrow;
    }
  }

  static Future<void> deleteRoute(String numeroRuta) async {
    // Endpoints log says: /rutas/destino/eliminar is POST
    final url = Uri.parse('${ApiConfig.baseUrl}/rutas/destino/eliminar');
    debugPrint('POST (DELETE): $url');
    final body = jsonEncode({'numero_ruta': numeroRuta});
    debugPrint('Body: $body');
    try {
      final response = await _client.post(url, headers: _headers, body: body);
      debugPrint('Status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode != 200 && response.statusCode != 201 && response.statusCode != 204) {
        throw Exception('Failed to delete route: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting route: $e');
      rethrow;
    }
  }

  // --- VEHICLE (VEHICULO) ENDPOINTS ---

  static Future<List<TransportUnit>> getVehiculos() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/vehiculos/vehiculo/todos');
    debugPrint('GET: $url');
    try {
      final response = await _client.get(url, headers: _headers);
      debugPrint('Status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((json) => TransportUnit.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load vehicles: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting vehicles: $e');
      rethrow;
    }
  }

  static Future<TransportUnit> registerVehiculo(TransportUnit unit) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/vehiculos/vehiculo/registrar');
    debugPrint('POST: $url');
    final body = jsonEncode({
      'placa': unit.plate,
      'modelo': unit.model,
      'color': unit.color,
      'anofabricacion': unit.yearOfManufacture,
      'cooperativa_id': unit.cooperativeId,
    });
    debugPrint('Body: $body');
    try {
      final response = await _client.post(url, headers: _headers, body: body);
      debugPrint('Status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return TransportUnit.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to register vehicle: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error registering vehicle: $e');
      rethrow;
    }
  }

  static Future<TransportUnit> updateVehiculo(TransportUnit unit) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/vehiculos/vehiculo/actualizar/${unit.plate}');
    debugPrint('PATCH: $url');
    final body = jsonEncode({
      'modelo': unit.model,
      'color': unit.color,
      'anofabricacion': unit.yearOfManufacture,
      'cooperativa_id': unit.cooperativeId,
    });
    debugPrint('Body: $body');
    try {
      final response = await _client.patch(url, headers: _headers, body: body);
      debugPrint('Status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200) {
        return TransportUnit.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update vehicle: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating vehicle: $e');
      rethrow;
    }
  }

  static Future<void> deleteVehiculo(String placa) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/vehiculos/vehiculo/eliminar');
    debugPrint('DELETE: $url');
    final body = jsonEncode({'placa': placa});
    debugPrint('Body: $body');
    try {
      final response = await _client.delete(url, headers: _headers, body: body);
      debugPrint('Status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete vehicle: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting vehicle: $e');
      rethrow;
    }
  }

  // --- PERSONAS (DRIVER) ENDPOINTS ---

  static Future<List<Driver>> getPersonas() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/personas/Todos');
    debugPrint('GET: $url');
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> list = [];
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map) {
          if (decoded.containsKey('data') && decoded['data'] is List) {
            list = decoded['data'];
          } else if (decoded.containsKey('personas') && decoded['personas'] is List) {
            list = decoded['personas'];
          } else if (decoded.containsKey('result') && decoded['result'] is List) {
            list = decoded['result'];
          }
        }
        return list.map((json) => Driver.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load personas: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting personas: $e');
      rethrow;
    }
  }

  static Future<Driver> registerPersona(Driver driver) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/personas/Registrar');
    debugPrint('POST: $url');
    final body = jsonEncode({
      'cedula': driver.id,
      'nombre': driver.name,
      'apellido': driver.lastName,
      'email': driver.email,
      'telefono': driver.phone,
      'edad': driver.age,
    });
    debugPrint('Body: $body');
    try {
      final response = await _client.post(url, headers: _headers, body: body);
      debugPrint('Status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Driver.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to register persona: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error registering persona: $e');
      rethrow;
    }
  }

  static Future<Driver> updatePersona(Driver driver) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/personas/Update/${driver.id}');
    debugPrint('PATCH: $url');
    final body = jsonEncode({
      'nombre': driver.name,
      'apellido': driver.lastName,
      'email': driver.email,
      'telefono': driver.phone,
      'edad': driver.age,
    });
    debugPrint('Body: $body');
    try {
      final response = await _client.patch(url, headers: _headers, body: body);
      debugPrint('Status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200) {
        return Driver.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update persona: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating persona: $e');
      rethrow;
    }
  }

  static Future<void> deletePersona(String cedula) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/personas/Delete/$cedula');
    debugPrint('DELETE: $url');
    try {
      final response = await _client.delete(url, headers: _headers);
      debugPrint('Status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete persona: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error deleting persona: $e');
      rethrow;
    }
  }
}
