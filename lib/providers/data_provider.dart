import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cooperative.dart';
import '../models/route.dart';
import '../models/transport_unit.dart';
import '../models/driver.dart';
import '../models/system_user.dart';
import '../models/viaje.dart';
import '../services/api_service.dart';

class DataProvider with ChangeNotifier {
  List<Cooperative> _cooperatives = [];
  List<TransportRoute> _routes = [];
  List<TransportUnit> _units = [];
  List<Driver> _drivers = [];
  List<SystemUser> _systemUsers = [];
  List<Viaje> _viajes = [];
  bool _isLoading = false;
  Timer? _viajesPollingTimer;

  List<Cooperative> get cooperatives => _cooperatives;
  List<TransportRoute> get routes => _routes;
  List<TransportUnit> get units => _units;
  List<Driver> get drivers => _drivers;
  List<SystemUser> get systemUsers => _systemUsers;
  List<Viaje> get viajes => _viajes;
  bool get isLoading => _isLoading;

  DataProvider() {
    _loadData();
  }

  @override
  void dispose() {
    _viajesPollingTimer?.cancel();
    super.dispose();
  }

  // Load data from API and SharedPreferences (for drivers & assignments)
  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Load cooperatives from API
      _cooperatives = await ApiService.getCooperativas();
    } catch (e) {
      debugPrint('Error loading cooperatives from API: $e');
    }

    try {
      // 2. Load routes from API
      _routes = await ApiService.getRoutes();
    } catch (e) {
      debugPrint('Error loading routes from API: $e');
    }

    try {
      // 3. Load vehicles from API
      _units = await ApiService.getVehiculos();
    } catch (e) {
      debugPrint('Error loading vehicles from API: $e');
    }

    try {
      // 4. Load drivers (personas) from API
      final apiPersonas = await ApiService.getPersonas();
      final prefs = await SharedPreferences.getInstance();
      
      // Load mappings from SharedPreferences
      final mappingsJson = prefs.getString('persona_cooperative_mappings') ?? '{}';
      final Map<String, dynamic> mappings = jsonDecode(mappingsJson);

      // Load cached drivers to retrieve their cooperativeId
      final driversJson = prefs.getString('drivers') ?? '[]';
      final List<dynamic> localDriversList = jsonDecode(driversJson);
      final Map<String, String> localDriverCoops = {};
      for (final json in localDriversList) {
        try {
          final d = Driver.fromJson(json as Map<String, dynamic>);
          if (d.cooperativeId.isNotEmpty) {
            localDriverCoops[d.id] = d.cooperativeId;
          }
        } catch (_) {}
      }

      _drivers = apiPersonas.map((driver) {
        String? coopId = mappings[driver.id]?.toString();
        coopId ??= localDriverCoops[driver.id];

        // Fallback: If no cooperative mapping exists, default to the first cooperative
        if ((coopId == null || coopId.isEmpty) && _cooperatives.isNotEmpty) {
          coopId = _cooperatives.first.id;
        }

        if (coopId != null && coopId.isNotEmpty) {
          return driver.copyWith(cooperativeId: coopId);
        }
        return driver;
      }).toList();

      // Proactively sync mappings back to SharedPreferences cache
      await _saveLocalCache();
    } catch (e) {
      debugPrint('Error loading drivers from API: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        final driversJson = prefs.getString('drivers') ?? '[]';
        final driversList = jsonDecode(driversJson) as List;
        _drivers = driversList
            .map((json) => Driver.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (err) {
        debugPrint('Error loading cached local drivers: $err');
      }
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      // Load route and driver assignments cache if any
      final assignmentsJson = prefs.getString('unit_assignments') ?? '{}';
      final Map<String, dynamic> assignments = jsonDecode(assignmentsJson);

      for (int i = 0; i < _units.length; i++) {
        final placa = _units[i].plate;
        if (assignments.containsKey(placa)) {
          final data = assignments[placa] as Map<String, dynamic>;
          _units[i] = _units[i].copyWith(
            driverId: data['driverId'] as String?,
            routeId: data['routeId'] as String?,
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading cached local data: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('system_users') ?? '[]';
      final List<dynamic> usersList = jsonDecode(usersJson);
      _systemUsers = usersList.map((json) => SystemUser.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Error loading system users: $e');
    }

    try {
      // 5. Cargar viajes desde API (SIN persistencia local, siempre desde BD)
      await _fetchViajesFromApi();
    } catch (e) {
      debugPrint('Error loading viajes from API: $e');
      _viajes = [];
    }

    _isLoading = false;
    notifyListeners();

    // Iniciar polling automático de viajes cada 10 segundos
    _viajesPollingTimer?.cancel();
    _viajesPollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchViajesFromApi();
    });
  }

  /// Carga los viajes desde el API (lista básica + detalle en paralelo).
  /// NO persiste nada en SharedPreferences.
  Future<void> _fetchViajesFromApi() async {
    try {
      final basicViajes = await ApiService.getViajes();
      final detailedViajes = await Future.wait(
        basicViajes.map((v) async {
          try {
            return await ApiService.getViajeById(v.idViaje);
          } catch (e) {
            debugPrint('Error loading detail viaje ${v.idViaje}: $e');
            return v;
          }
        }),
      );
      _viajes = detailedViajes;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching viajes from API: $e');
    }
  }

  // Save local assignments & drivers cache
  Future<void> _saveLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        'drivers',
        jsonEncode(_drivers.map((d) => d.toJson()).toList()),
      );

      await prefs.setString(
        'system_users',
        jsonEncode(_systemUsers.map((u) => u.toJson()).toList()),
      );

      final Map<String, String> mappings = {};
      for (final driver in _drivers) {
        if (driver.cooperativeId.isNotEmpty) {
          mappings[driver.id] = driver.cooperativeId;
        }
      }
      await prefs.setString('persona_cooperative_mappings', jsonEncode(mappings));

      final Map<String, dynamic> assignments = {};
      for (final unit in _units) {
        assignments[unit.plate] = {
          'driverId': unit.driverId,
          'routeId': unit.routeId,
        };
      }
      await prefs.setString('unit_assignments', jsonEncode(assignments));
    } catch (e) {
      debugPrint('Error saving local cache: $e');
    }
  }

  // --- Cooperative CRUD ---

  Future<void> addCooperative({
    required String id,
    required String name,
    required String description,
    required String location,
    required String schedule,
  }) async {
    final cooperative = Cooperative(
      id: id,
      name: name,
      description: description,
      location: location,
      schedule: schedule,
      createdAt: DateTime.now(),
    );

    _isLoading = true;
    notifyListeners();

    try {
      final created = await ApiService.createCooperativa(cooperative);
      _cooperatives.add(created);
    } catch (e) {
      debugPrint('Error creating cooperative: $e');
      // local fallback if offline/failed
      _cooperatives.add(cooperative);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateCooperative({
    required String id,
    required String name,
    required String description,
    required String location,
    required String schedule,
  }) async {
    final cooperative = Cooperative(
      id: id,
      name: name,
      description: description,
      location: location,
      schedule: schedule,
      createdAt: DateTime.now(),
    );

    _isLoading = true;
    notifyListeners();

    try {
      final updated = await ApiService.updateCooperativa(cooperative);
      final index = _cooperatives.indexWhere((c) => c.id == id);
      if (index != -1) {
        _cooperatives[index] = updated;
      }
    } catch (e) {
      debugPrint('Error updating cooperative: $e');
      // local fallback update
      final index = _cooperatives.indexWhere((c) => c.id == id);
      if (index != -1) {
        _cooperatives[index] = cooperative;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteCooperative(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.deleteCooperativa(id);
      _cooperatives.removeWhere((c) => c.id == id);
      _routes.removeWhere((r) => r.cooperativeId == id);
      _units.removeWhere((u) => u.cooperativeId == id);
      _drivers.removeWhere((d) => d.cooperativeId == id);
      await _saveLocalCache();
    } catch (e) {
      debugPrint('Error deleting cooperative: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- Route CRUD ---

  Future<void> addRoute({
    required String id,
    required String name,
    required String description,
    required int fare,
    required String cooperativeId,
    int? originId,
    int? destinationId,
    List<RouteStop> stops = const [],
  }) async {
    final route = TransportRoute(
      id: id,
      name: name,
      description: description,
      fare: fare,
      origin: stops.isNotEmpty ? stops.first.name : 'Origen',
      destination: stops.isNotEmpty ? stops.last.name : 'Destino',
      originId: originId,
      destinationId: destinationId,
      cooperativeId: cooperativeId,
      stops: stops,
      createdAt: DateTime.now(),
    );

    _isLoading = true;
    notifyListeners();

    try {
      final created = await ApiService.createRoute(route);
      _routes.add(created);
    } catch (e) {
      debugPrint('Error creating route: $e');
      _routes.add(route);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateRoute({
    required String id,
    required String name,
    required String description,
    required int fare,
    required String cooperativeId,
    int? originId,
    int? destinationId,
    List<RouteStop> stops = const [],
  }) async {
    final route = TransportRoute(
      id: id,
      name: name,
      description: description,
      fare: fare,
      origin: stops.isNotEmpty ? stops.first.name : 'Origen',
      destination: stops.isNotEmpty ? stops.last.name : 'Destino',
      originId: originId,
      destinationId: destinationId,
      cooperativeId: cooperativeId,
      stops: stops,
      createdAt: DateTime.now(),
    );

    _isLoading = true;
    notifyListeners();

    try {
      final updated = await ApiService.updateRoute(route);
      final index = _routes.indexWhere((r) => r.id == id);
      if (index != -1) {
        _routes[index] = updated;
      }
    } catch (e) {
      debugPrint('Error updating route: $e');
      final index = _routes.indexWhere((r) => r.id == id);
      if (index != -1) {
        _routes[index] = route;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteRoute(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.deleteRoute(id);
      _routes.removeWhere((r) => r.id == id);
      for (int i = 0; i < _units.length; i++) {
        if (_units[i].routeId == id) {
          _units[i] = _units[i].copyWith(routeId: null);
        }
      }
      await _saveLocalCache();
    } catch (e) {
      debugPrint('Error deleting route: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  List<TransportRoute> getRoutesByCooperative(String cooperativeId) {
    return _routes.where((r) => r.cooperativeId == cooperativeId).toList();
  }

  // --- Driver CRUD ---

  Future<void> addDriver({
    required String id,
    required String name,
    required String lastName,
    required String email,
    required String phone,
    required int age,
    required String cooperativeId,
  }) async {
    final driver = Driver(
      id: id,
      name: name,
      lastName: lastName,
      email: email,
      phone: phone,
      age: age,
      cooperativeId: cooperativeId,
      createdAt: DateTime.now(),
    );

    _isLoading = true;
    notifyListeners();

    try {
      final created = await ApiService.registerPersona(driver);
      final finalDriver = created.copyWith(
        id: created.id.isNotEmpty ? created.id : id,
        cooperativeId: cooperativeId,
      );
      _drivers.add(finalDriver);
      await _saveLocalCache();
    } catch (e) {
      debugPrint('Error registering driver/persona: $e');
      _drivers.add(driver);
      await _saveLocalCache();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateDriver({
    required String id,
    required String name,
    required String lastName,
    required String email,
    required String phone,
    required int age,
    required String cooperativeId,
  }) async {
    final driver = Driver(
      id: id,
      name: name,
      lastName: lastName,
      email: email,
      phone: phone,
      age: age,
      cooperativeId: cooperativeId,
      createdAt: DateTime.now(),
    );

    _isLoading = true;
    notifyListeners();

    try {
      final updated = await ApiService.updatePersona(driver);
      final finalDriver = updated.copyWith(
        id: updated.id.isNotEmpty ? updated.id : id,
        cooperativeId: cooperativeId,
      );
      final index = _drivers.indexWhere((d) => d.id == id);
      if (index != -1) {
        _drivers[index] = finalDriver;
      }
      await _saveLocalCache();
    } catch (e) {
      debugPrint('Error updating driver/persona: $e');
      final index = _drivers.indexWhere((d) => d.id == id);
      if (index != -1) {
        _drivers[index] = driver;
      }
      await _saveLocalCache();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteDriver(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.deletePersona(id);
      _drivers.removeWhere((d) => d.id == id);
      for (int i = 0; i < _units.length; i++) {
        if (_units[i].driverId == id) {
          _units[i] = _units[i].copyWith(driverId: null);
        }
      }
      await _saveLocalCache();
    } catch (e) {
      debugPrint('Error deleting driver/persona: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  List<Driver> getDriversByCooperative(String cooperativeId) {
    return _drivers.where((d) => d.cooperativeId == cooperativeId).toList();
  }

  // --- Transport Unit CRUD ---

  Future<void> addTransportUnit({
    required String plate,
    required String model,
    required String color,
    required String yearOfManufacture,
    required String cooperativeId,
  }) async {
    final unit = TransportUnit(
      id: plate,
      plate: plate,
      model: model,
      color: color,
      yearOfManufacture: yearOfManufacture,
      cooperativeId: cooperativeId,
      createdAt: DateTime.now(),
    );

    _isLoading = true;
    notifyListeners();

    try {
      final created = await ApiService.registerVehiculo(unit);
      _units.add(created);
      await _saveLocalCache();
    } catch (e) {
      debugPrint('Error registering vehicle: $e');
      _units.add(unit);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateTransportUnit({
    required String id,
    required String model,
    required String color,
    required String yearOfManufacture,
    required String cooperativeId,
    String? routeId,
    String? driverId,
  }) async {
    final unit = TransportUnit(
      id: id,
      plate: id,
      model: model,
      color: color,
      yearOfManufacture: yearOfManufacture,
      cooperativeId: cooperativeId,
      driverId: driverId,
      routeId: routeId,
      createdAt: DateTime.now(),
    );

    _isLoading = true;
    notifyListeners();

    try {
      final updated = await ApiService.updateVehiculo(unit);
      final index = _units.indexWhere((u) => u.id == id);
      if (index != -1) {
        _units[index] = updated.copyWith(
          driverId: driverId,
          routeId: routeId,
        );
      }
      await _saveLocalCache();
    } catch (e) {
      debugPrint('Error updating vehicle: $e');
      final index = _units.indexWhere((u) => u.id == id);
      if (index != -1) {
        _units[index] = unit;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> assignDriverToUnit(String unitId, String? driverId) async {
    final index = _units.indexWhere((u) => u.id == unitId);
    if (index != -1) {
      _units[index] = _units[index].copyWith(driverId: driverId);
      await _saveLocalCache();
      notifyListeners();
    }
  }

  Future<void> assignRouteToUnit(String unitId, String? routeId) async {
    final index = _units.indexWhere((u) => u.id == unitId);
    if (index != -1) {
      _units[index] = _units[index].copyWith(routeId: routeId);
      await _saveLocalCache();
      notifyListeners();
    }
  }

  Future<void> deleteTransportUnit(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.deleteVehiculo(id);
      _units.removeWhere((u) => u.id == id);
      await _saveLocalCache();
    } catch (e) {
      debugPrint('Error deleting vehicle: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  List<TransportUnit> getUnitsByRoute(String routeId) {
    // Obtener las placas de los vehículos que tienen un viaje activo para esta ruta
    final activePlatesForRoute = _viajes
        .where((v) => v.idRuta == routeId || v.rutaNumero == routeId)
        .map((v) => v.idVehiculo.isNotEmpty ? v.idVehiculo : (v.vehiculoPlaca ?? ''))
        .toSet();

    return _units.where((u) => activePlatesForRoute.contains(u.plate)).toList();
  }

  List<TransportUnit> getUnitsByCooperative(String cooperativeId) {
    return _units.where((u) => u.cooperativeId == cooperativeId).toList();
  }

  int getTotalRoutes() => _routes.length;
  int getTotalUnits() => _units.length;

  int getRouteCountForCooperative(String cooperativeId) {
    return _routes.where((r) => r.cooperativeId == cooperativeId).length;
  }

  int getUnitCountForRoute(String routeId) {
    return getUnitsByRoute(routeId).length;
  }

  // --- System User CRUD ---

  Future<void> addSystemUser(SystemUser user) async {
    _systemUsers.add(user);
    await _saveLocalCache();
    notifyListeners();
  }

  Future<void> updateSystemUser(SystemUser user) async {
    final index = _systemUsers.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _systemUsers[index] = user;
      await _saveLocalCache();
      notifyListeners();
    }
  }

  Future<void> deleteSystemUser(String id) async {
    _systemUsers.removeWhere((u) => u.id == id);
    await _saveLocalCache();
    notifyListeners();
  }

  // --- VIAJES CRUD ---

  /// Crea un viaje en el API. Después recarga la lista de viajes desde la BD.
  Future<Viaje?> createViaje({
    required DateTime fechaInicio,
    required DateTime fechaFinal,
    required double lactitud,
    required double longitud,
    required String idVehiculo,
    required String idRuta,
    int idUser = 1,
    int? incidenciaId,
  }) async {
    try {
      final viaje = await ApiService.createViaje(
        fechaInicio: fechaInicio,
        fechaFinal: fechaFinal,
        lactitud: lactitud,
        longitud: longitud,
        idUser: idUser,
        idVehiculo: idVehiculo,
        idRuta: idRuta,
        incidenciaId: incidenciaId,
      );
      // Recargar desde la BD para tener el estado real
      await _fetchViajesFromApi();
      return viaje;
    } catch (e) {
      debugPrint('Error creating viaje: $e');
      return null;
    }
  }

  /// Elimina un viaje por ID y recarga desde la BD.
  Future<void> deleteViaje(int id) async {
    try {
      await ApiService.deleteViaje(id);
      await _fetchViajesFromApi();
    } catch (e) {
      debugPrint('Error deleting viaje: $e');
    }
  }

  /// Actualiza un viaje por ID y recarga desde la BD.
  Future<void> updateViaje(int id, {
    DateTime? fechaInicio,
    DateTime? fechaFinal,
    double? lactitud,
    double? longitud,
    int? idUser,
    String? idVehiculo,
    String? idRuta,
    int? incidenciaId,
  }) async {
    try {
      await ApiService.updateViaje(
        id,
        fechaInicio: fechaInicio,
        fechaFinal: fechaFinal,
        lactitud: lactitud,
        longitud: longitud,
        idUser: idUser,
        idVehiculo: idVehiculo,
        idRuta: idRuta,
        incidenciaId: incidenciaId,
      );
      await _fetchViajesFromApi();
    } catch (e) {
      debugPrint('Error updating viaje: $e');
    }
  }

  /// Recarga manual de viajes (delega al fetcher interno).
  Future<void> refreshViajes() => _fetchViajesFromApi();

  /// Devuelve los viajes activos directamente de la memoria (ya sincronizados con la BD).
  List<Viaje> getViajesActivos() => List.unmodifiable(_viajes);

  /// Devuelve el viaje activo de un vehículo por su placa, si existe.
  Viaje? getViajeByVehiculo(String placa) {
    try {
      return _viajes.firstWhere(
        (v) => v.idVehiculo == placa || v.vehiculoPlaca == placa,
      );
    } catch (_) {
      return null;
    }
  }
}
