import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/cooperative.dart';
import '../../models/system_user.dart';
import '../../models/route.dart';
import '../../models/viaje.dart';

import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/route_card.dart';
import '../../widgets/transport_unit_card.dart';
import '../routes/route_form_screen.dart';
import '../users/user_form_screen.dart';
import 'cooperative_form_screen.dart';
import 'driver_form_screen.dart';
import '../units/transport_unit_form_screen.dart';

/// Pantalla principal del panel administrativo.
/// Esta vista centraliza la gestión de cooperativas, rutas, buses, choferes y usuarios,
/// además de mostrar un dashboard con viajes activos en un mapa.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// Estado de la pantalla principal.
/// Mantiene el control de la pestaña activa, la cooperativa seleccionada y la lógica
/// de los diálogos, filtros y widgets dinámicos utilizados en la interfaz.
class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  String? _selectedCooperativeId;
  String? _selectedFilterRouteId;
  int _activeTabIndex = 0;
  LatLng? _mapCenterOverride;

  /// Inicializa el estado base de la pantalla antes de construir la UI.
  @override
  void initState() {
    super.initState();
  }

  /// Crea y configura el controlador de pestañas cuando la pantalla lo necesita.
  /// Este controlador permite cambiar entre los distintos módulos del panel y sincronizar
  /// el estado visual con el índice de la pestaña seleccionada.
  void _initTabController() {
    if (_tabController == null) {
      _tabController = TabController(length: 5, vsync: this);
      _tabController!.addListener(() {
        if (!mounted) return;
        if (_tabController!.index != _activeTabIndex) {
          setState(() {
            _activeTabIndex = _tabController!.index;
          });
        }
      });
    }
  }

  /// Libera el controlador de pestañas y los recursos asociados al salir de la pantalla.
  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  /// Muestra un cuadro de confirmación antes de borrar una cooperativa.
  /// El mensaje incluye el nombre de la entidad y advierte que también se eliminarán
  /// rutas, buses y choferes asociados a esa cooperativa.
  void _showDeleteCooperativeDialog(
      BuildContext context, Cooperative cooperative) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
            '¿Está seguro de eliminar la cooperativa "${cooperative.name}"? Esto también eliminará todas sus rutas, buses y choferes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<DataProvider>().deleteCooperative(cooperative.id);
              Navigator.of(ctx).pop();
              setState(() {
                _selectedCooperativeId = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cooperativa eliminada')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  /// Abre un diálogo para cambiar la cooperativa activa.
  /// Muestra la lista disponible y permite seleccionar otra entidad, actualizando el
  /// filtro y el contexto de los datos mostrados en la pantalla.
  void _showCooperativeSelectionDialog(
      BuildContext context, DataProvider dataProvider) {
    final cooperatives = dataProvider.cooperatives;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            'Seleccionar Cooperativa',
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: cooperatives.length,
              itemBuilder: (context, index) {
                final coop = cooperatives[index];
                final isSelected = coop.id == _selectedCooperativeId;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected
                        ? Colors.green.shade100
                        : Colors.grey.shade100,
                    child: Icon(
                      Icons.business,
                      color: isSelected
                          ? Colors.green.shade800
                          : Colors.grey.shade700,
                    ),
                  ),
                  title: Text(
                    coop.name,
                    style: GoogleFonts.poppins(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedCooperativeId = coop.id;
                      _selectedFilterRouteId = null;
                    });
                    Navigator.pop(ctx);
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

  /// Presenta un diálogo de confirmación antes de eliminar a un chofer.
  /// También informa que el chofer será desasignado de cualquier unidad que tuviera.
  void _showDeleteDriverDialog(
      BuildContext context, String driverId, String driverName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmar eliminación',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
            '¿Está seguro de eliminar al chofer "$driverName"? Se desasignará de cualquier unidad.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DataProvider>().deleteDriver(driverId);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chofer eliminado')),
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

  /// Construye la interfaz principal del panel administrativo.
  /// El flujo incluye estados de carga, pantallas vacías, selección de cooperativa y
  /// la renderización de las pestañas según el tamaño de pantalla.
  /// Aquí se deciden qué vistas mostrar según la cooperativa activa, si hay datos
  /// disponibles y si el panel se está visualizando en escritorio o móvil.
  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final cooperatives = dataProvider.cooperatives;

        if (dataProvider.isLoading && cooperatives.isEmpty) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.orange,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cargando panel de control...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (cooperatives.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(
                'Panel de Control',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 18),
              ),
              elevation: 0,
              backgroundColor: const Color(0xFF1A1F2B),
              foregroundColor: Colors.white,
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'Opciones',
                  onSelected: (value) async {
                    if (value == 'add') {
                      final newId = await Navigator.of(context).push<String>(
                        MaterialPageRoute(
                          builder: (context) => const CooperativeFormScreen(),
                        ),
                      );
                      if (newId != null && mounted) {
                        setState(() {
                          _selectedCooperativeId = newId;
                          _selectedFilterRouteId = null;
                        });
                      }
                    } else if (value == 'logout') {
                      context.read<AuthProvider>().logout();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'add',
                      child: Row(
                        children: [
                          Icon(Icons.add_business_rounded),
                          SizedBox(width: 8),
                          Text('Agregar cooperativa'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout_rounded),
                          SizedBox(width: 8),
                          Text('Cerrar sesión'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.business_outlined,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No hay cooperativas',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Registra una cooperativa para comenzar a gestionar rutas, unidades y conductores.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final newId = await Navigator.of(context).push<String>(
                          MaterialPageRoute(
                            builder: (context) => const CooperativeFormScreen(),
                          ),
                        );
                        if (newId != null && mounted) {
                          setState(() {
                            _selectedCooperativeId = newId;
                            _selectedFilterRouteId = null;
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1F2B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add_business_rounded),
                      label: Text('Crear Cooperativa',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        _selectedCooperativeId ??= cooperatives.first.id;

        final matching =
            cooperatives.where((c) => c.id == _selectedCooperativeId);
        Cooperative activeCooperative;
        if (matching.isNotEmpty) {
          activeCooperative = matching.first;
        } else {
          activeCooperative = cooperatives.first;
          _selectedCooperativeId = activeCooperative.id;
        }

        _initTabController();

        final isDesktop = MediaQuery.of(context).size.width > 900;

        if (isDesktop) {
          return Scaffold(
            backgroundColor: Colors.grey.shade50,
            appBar: AppBar(
              title: Row(
                children: [
                  const Icon(Icons.directions_bus,
                      color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Panel Administrativo - ${activeCooperative.name}',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              elevation: 0,
              backgroundColor: const Color(0xFF1A1F2B),
              foregroundColor: Colors.white,
              actions: [
                TextButton.icon(
                  onPressed: () =>
                      _showCooperativeSelectionDialog(context, dataProvider),
                  icon:
                      const Icon(Icons.swap_horiz_rounded, color: Colors.white),
                  label: Text('Cambiar Cooperativa',
                      style: GoogleFonts.poppins(color: Colors.white)),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final newId = await Navigator.of(context).push<String>(
                      MaterialPageRoute(
                        builder: (context) => const CooperativeFormScreen(),
                      ),
                    );
                    if (newId != null && mounted) {
                      setState(() {
                        _selectedCooperativeId = newId;
                        _selectedFilterRouteId = null;
                      });
                    }
                  },
                  icon: const Icon(Icons.add_business_rounded,
                      color: Colors.white),
                  label: Text('Nueva Cooperativa',
                      style: GoogleFonts.poppins(color: Colors.white)),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CooperativeFormScreen(
                            cooperative: activeCooperative),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  label: Text('Editar Actual',
                      style: GoogleFonts.poppins(color: Colors.white)),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  tooltip: 'Cerrar Sesión',
                  onPressed: () => context.read<AuthProvider>().logout(),
                ),
                const SizedBox(width: 16),
              ],
            ),
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _activeTabIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _activeTabIndex = index;
                      _tabController?.index = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: const Color(0xFF1A1F2B),
                  unselectedLabelTextStyle: GoogleFonts.poppins(
                      color: Colors.grey.shade400, fontSize: 12),
                  selectedLabelTextStyle: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                  unselectedIconTheme:
                      IconThemeData(color: Colors.grey.shade400),
                  selectedIconTheme: const IconThemeData(color: Colors.white),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.route_outlined),
                      label: Text('Rutas'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.directions_bus_outlined),
                      label: Text('Buses'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_alt_outlined),
                      label: Text('Choferes'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      label: Text('Usuarios'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: IndexedStack(
                          index: _activeTabIndex,
                          children: [
                            _buildDashboardTab(dataProvider, activeCooperative),
                            _buildRoutesTab(dataProvider, activeCooperative),
                            _buildBusesTab(dataProvider, activeCooperative),
                            _buildDriversTab(dataProvider, activeCooperative),
                            _buildUsersTab(dataProvider),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            floatingActionButton: _buildFAB(activeCooperative),
          );
        }

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: Text(
              activeCooperative.name,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            elevation: 0,
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'Opciones',
                onSelected: (value) {
                  if (value == 'change') {
                    _showCooperativeSelectionDialog(context, dataProvider);
                  } else if (value == 'add') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CooperativeFormScreen(),
                      ),
                    );
                  } else if (value == 'edit') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CooperativeFormScreen(
                            cooperative: activeCooperative),
                      ),
                    );
                  } else if (value == 'delete') {
                    _showDeleteCooperativeDialog(context, activeCooperative);
                  } else if (value == 'logout') {
                    context.read<AuthProvider>().logout();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'change',
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz_rounded),
                        SizedBox(width: 8),
                        Text('Cambiar cooperativa'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'add',
                    child: Row(
                      children: [
                        Icon(Icons.add_business_rounded),
                        SizedBox(width: 8),
                        Text('Agregar nueva cooperativa'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded),
                        SizedBox(width: 8),
                        Text('Editar cooperativa actual'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar cooperativa actual',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded),
                        SizedBox(width: 8),
                        Text('Cerrar sesión'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'DASHBOARD', icon: Icon(Icons.dashboard_outlined)),
                Tab(text: 'RUTAS', icon: Icon(Icons.route_outlined)),
                Tab(text: 'BUSES', icon: Icon(Icons.directions_bus_outlined)),
                Tab(text: 'CHOFERES', icon: Icon(Icons.people_alt_outlined)),
                Tab(text: 'USUARIOS', icon: Icon(Icons.person_outline)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildDashboardTab(dataProvider, activeCooperative),
              _buildRoutesTab(dataProvider, activeCooperative),
              _buildBusesTab(dataProvider, activeCooperative),
              _buildDriversTab(dataProvider, activeCooperative),
              _buildUsersTab(dataProvider),
            ],
          ),
          floatingActionButton: _buildFAB(activeCooperative),
        );
      },
    );
  }

  /// Construye la vista de rutas para la cooperativa seleccionada.
  /// Obtiene las rutas asociadas, verifica si hay contenido y muestra tarjetas con la
  /// información relevante y la posibilidad de editar cada ruta.
  Widget _buildRoutesTab(DataProvider dataProvider, Cooperative cooperative) {
    final routes = dataProvider.getRoutesByCooperative(cooperative.id);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    if (routes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.route_outlined,
                  size: 64, color: Colors.green.shade300),
            ),
            const SizedBox(height: 24),
            Text('No hay rutas registradas',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Text('Comienza agregando una nueva ruta',
                style: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    if (isDesktop) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 450,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          // Aumentamos ligeramente la relación de aspecto para dar espacio al texto de los buses asignados
          childAspectRatio: 1.8,
        ),
        itemCount: routes.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final route = routes[index];
          final unitCount = dataProvider.getUnitCountForRoute(route.id);
          final routeUnits = dataProvider.getUnitsByRoute(route.id);
          return RouteCard(
            route: route,
            unitCount: unitCount,
            assignedUnits: routeUnits,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => RouteFormScreen(
                    cooperativeId: cooperative.id,
                    route: route,
                  ),
                ),
              );
            },
          );
        },
      );
    }

    return ListView.builder(
      itemCount: routes.length,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemBuilder: (context, index) {
        final route = routes[index];
        final unitCount = dataProvider.getUnitCountForRoute(route.id);
        final routeUnits = dataProvider.getUnitsByRoute(route.id);

        return RouteCard(
          route: route,
          unitCount: unitCount,
          assignedUnits: routeUnits,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => RouteFormScreen(
                  cooperativeId: cooperative.id,
                  route: route,
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Construye la vista de buses o unidades de transporte.
  /// Reúne las unidades de la cooperativa, resuelve el nombre del chofer asignado y
  /// muestra una tarjeta por cada bus para permitir su edición o revisión rápida.
  Widget _buildBusesTab(DataProvider dataProvider, Cooperative cooperative) {
    final units = dataProvider.getUnitsByCooperative(cooperative.id);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    if (units.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.directions_bus_outlined,
                  size: 64, color: Colors.orange.shade300),
            ),
            const SizedBox(height: 24),
            Text('No hay buses registrados',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Text('Registra un bus y asígnale un chofer',
                style: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    Widget buildUnitCard(dynamic unit) {
      final matchingDrivers =
          dataProvider.drivers.where((d) => d.id == unit.driverId);
      final driverName = matchingDrivers.isNotEmpty
          ? '${matchingDrivers.first.name} ${matchingDrivers.first.lastName}'
          : null;
      return TransportUnitCard(
        unit: unit,
        driverName: driverName,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TransportUnitFormScreen(
                cooperativeId: cooperative.id,
                unit: unit,
              ),
            ),
          );
        },
      );
    }

    if (isDesktop) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 450,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.2,
        ),
        itemCount: units.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          return buildUnitCard(units[index]);
        },
      );
    }

    return ListView.builder(
      itemCount: units.length,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemBuilder: (context, index) {
        return buildUnitCard(units[index]);
      },
    );
  }

  /// Construye la vista de choferes para la cooperativa activa.
  /// Muestra una tarjeta con los datos personales del chofer y ofrece acciones de edición
  /// o eliminación desde un menú contextual.
  Widget _buildDriversTab(DataProvider dataProvider, Cooperative cooperative) {
    final drivers = dataProvider.getDriversByCooperative(cooperative.id);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    if (drivers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.people_outline_rounded,
                  size: 64, color: Colors.blue.shade300),
            ),
            const SizedBox(height: 24),
            Text('No hay choferes registrados',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Text('Registra los choferes de la cooperativa aquí',
                style: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    Widget buildDriverCard(dynamic driver) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            radius: 24,
            child: Icon(Icons.person, color: Colors.blue.shade800, size: 28),
          ),
          title: Text(
            '${driver.name} ${driver.lastName}',
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.badge_outlined,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Flexible(
                            child: Text('C.I. ${driver.id}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey.shade600))),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Flexible(
                            child: Text(driver.phone,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey.shade600))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.email_outlined,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Flexible(
                            child: Text(driver.email,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey.shade600))),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cake_outlined,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Flexible(
                            child: Text('${driver.age} años',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey.shade600))),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DriverFormScreen(
                      cooperativeId: cooperative.id,
                      driver: driver,
                    ),
                  ),
                );
              } else if (value == 'delete') {
                _showDeleteDriverDialog(
                    context, driver.id, '${driver.name} ${driver.lastName}');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isDesktop) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 450,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.2,
        ),
        itemCount: drivers.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          return buildDriverCard(drivers[index]);
        },
      );
    }

    return ListView.builder(
      itemCount: drivers.length,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemBuilder: (context, index) {
        return buildDriverCard(drivers[index]);
      },
    );
  }

  /// Construye la vista de usuarios del sistema.
  /// Muestra los usuarios registrados con su rol y datos básicos, y permite editarlos o eliminarlos.
  Widget _buildUsersTab(DataProvider dataProvider) {
    final users = dataProvider.systemUsers;
    final isDesktop = MediaQuery.of(context).size.width > 900;

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.people_outline_rounded,
                  size: 64, color: Colors.teal.shade300),
            ),
            const SizedBox(height: 24),
            Text('No hay usuarios registrados',
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Text('Comienza agregando un nuevo usuario',
                style: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    Widget buildUserCard(SystemUser user) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: Colors.teal.shade100,
            radius: 24,
            child: Icon(Icons.security, color: Colors.teal.shade800, size: 28),
          ),
          title: Text(
            '${user.nombre} ${user.apellido}',
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.badge_outlined,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('C.I. ${user.cedula}',
                        style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(width: 12),
                    const Icon(Icons.admin_panel_settings_outlined,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(user.rol,
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email_outlined,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(user.correo,
                        style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              ],
            ),
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => UserFormScreen(
                      user: user,
                    ),
                  ),
                );
              } else if (value == 'delete') {
                _showDeleteUserDialog(context, user);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Editar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isDesktop) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 450,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 2.2,
        ),
        itemCount: users.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          return buildUserCard(users[index]);
        },
      );
    }

    return ListView.builder(
      itemCount: users.length,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemBuilder: (context, index) {
        return buildUserCard(users[index]);
      },
    );
  }

  /// Muestra un cuadro de confirmación para borrar un usuario del sistema.
  /// Se utiliza para evitar eliminaciones accidentales y aportar una confirmación visual.
  void _showDeleteUserDialog(BuildContext context, SystemUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmar eliminación',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
            '¿Está seguro de eliminar al usuario "${user.nombre} ${user.apellido}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DataProvider>().deleteSystemUser(user.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Usuario eliminado')),
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

  /// Define el botón flotante según la pestaña activa.
  /// Cada pestaña tiene un acción distinta: crear rutas, buses, choferes o usuarios.
  Widget? _buildFAB(Cooperative cooperative) {
    if (_activeTabIndex == 0) {
      return null;
    } else if (_activeTabIndex == 1) {
      return FloatingActionButton.extended(
        key: const ValueKey('fab_route'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  RouteFormScreen(cooperativeId: cooperative.id),
            ),
          );
        },
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Ruta'),
      );
    } else if (_activeTabIndex == 2) {
      return FloatingActionButton.extended(
        key: const ValueKey('fab_bus'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  TransportUnitFormScreen(cooperativeId: cooperative.id),
            ),
          );
        },
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.directions_bus),
        label: const Text('Nuevo Bus'),
      );
    } else if (_activeTabIndex == 3) {
      return FloatingActionButton.extended(
        key: const ValueKey('fab_driver'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  DriverFormScreen(cooperativeId: cooperative.id),
            ),
          );
        },
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo Chofer'),
      );
    } else if (_activeTabIndex == 4) {
      return FloatingActionButton.extended(
        key: const ValueKey('fab_system_user'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const UserFormScreen(),
            ),
          );
        },
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Nuevo Usuario'),
      );
    }
    return null;
  }

  /// Abre una hoja inferior con los detalles de un viaje activo.
  /// Se usa para mostrar información del viaje, ruta asignada, conductor, coordenadas y estado.
  void _showViajeBottomSheet(
    BuildContext context,
    Viaje viaje,
    TransportRoute? ruta,
  ) {
    final rutaNombre = viaje.rutaNombre ?? ruta?.name ?? viaje.idRuta;
    final placaBus = viaje.vehiculoPlaca ?? viaje.idVehiculo;
    final conductor = viaje.usuarioUsername ?? 'No registrado';
    final inicio = viaje.fechaInicio.toLocal().toString().substring(0, 16);
    final lat = viaje.lactitud.toStringAsFixed(6);
    final lng = viaje.longitud.toStringAsFixed(6);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.directions_bus,
                        color: Colors.orange.shade700, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          placaBus.isNotEmpty ? placaBus : 'Sin placa',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1F2B),
                          ),
                        ),
                        Text(
                          'Viaje #${viaje.idViaje}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'En viaje',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),
              // Detalles
              _buildDetailRow(Icons.route_outlined, 'Ruta',
                  rutaNombre.isNotEmpty ? rutaNombre : 'Sin asignar'),
              _buildDetailRow(Icons.person_outline, 'Conductor', conductor),
              _buildDetailRow(
                  Icons.access_time_outlined, 'Inicio de viaje', inicio),
              _buildDetailRow(Icons.location_on_outlined, 'Latitud', lat),
              _buildDetailRow(Icons.location_on_outlined, 'Longitud', lng),
              const SizedBox(height: 20),
              // Botón cerrar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text('Cerrar',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Crea una fila reutilizable para mostrar atributos en la hoja de detalle del viaje.
  /// Sirve para presentar la información de forma consistente y ordenada.
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF1A1F2B),
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el tablero principal con el mapa y la lista de unidades activas.
  /// Filtra los viajes por cooperativa y por ruta, genera los marcadores del mapa y
  /// permite interactuar con cada unidad para ver más información.
  Widget _buildDashboardTab(
      DataProvider dataProvider, Cooperative cooperative) {
    final routes = dataProvider.getRoutesByCooperative(cooperative.id);
    final viajesActivos = dataProvider.getViajesActivos();
    // Filtrar viajes cuyo vehículo pertenece a esta cooperativa
    final coopUnitPlates = dataProvider
        .getUnitsByCooperative(cooperative.id)
        .map((u) => u.plate)
        .toSet();
    final viajesFiltrados = viajesActivos
        .where((v) =>
            coopUnitPlates.contains(v.idVehiculo) ||
            (v.vehiculoPlaca != null &&
                coopUnitPlates.contains(v.vehiculoPlaca)))
        .toList();

    // Filtrar por ruta seleccionada si corresponde.
    final viajesMostrados = _selectedFilterRouteId == null
        ? viajesFiltrados
        : viajesFiltrados.where((v) {
            final targetRuta = v.idRuta.isNotEmpty ? v.idRuta : v.rutaNumero;
            return targetRuta == _selectedFilterRouteId;
          }).toList();

    // Marcadores: buses en viaje activo con coordenadas reales del viaje
    final markers = viajesMostrados.map((viaje) {
      final pos = LatLng(viaje.lactitud, viaje.longitud);

      // Datos adicionales de la ruta
      TransportRoute? unitRoute;
      try {
        unitRoute = routes.firstWhere(
            (r) => r.id == viaje.idRuta || r.id == viaje.rutaNumero);
      } catch (_) {}

      return Marker(
        point: pos,
        width: 48,
        height: 48,
        child: GestureDetector(
          onTap: () => _showViajeBottomSheet(context, viaje, unitRoute),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange.shade700, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.directions_bus,
              color: Colors.orange.shade800,
              size: 26,
            ),
          ),
        ),
      );
    }).toList();

    // Centro del mapa con prioridad a _mapCenterOverride si está definido
    LatLng center = _mapCenterOverride ?? const LatLng(10.4806, -66.9036);
    if (_mapCenterOverride == null) {
      if (_selectedFilterRouteId != null) {
        try {
          final selectedRoute =
              routes.firstWhere((r) => r.id == _selectedFilterRouteId);
          if (selectedRoute.stops.isNotEmpty) {
            center = LatLng(selectedRoute.stops.first.latitude,
                selectedRoute.stops.first.longitude);
          }
        } catch (_) {}
      } else if (viajesMostrados.isNotEmpty) {
        center = LatLng(
            viajesMostrados.first.lactitud, viajesMostrados.first.longitud);
      } else if (routes.isNotEmpty) {
        for (final r in routes) {
          if (r.stops.isNotEmpty) {
            center = LatLng(r.stops.first.latitude, r.stops.first.longitude);
            break;
          }
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Text(
                  'Monitoreo de Unidades',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1F2B),
                  ),
                ),
                const SizedBox(width: 8),
                // Badge: buses en viaje activo
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: viajesMostrados.isNotEmpty
                        ? Colors.orange.shade100
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${viajesMostrados.length} en viaje',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: viajesMostrados.isNotEmpty
                          ? Colors.orange.shade800
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
                const Spacer(),
                // Botón refrescar viajes
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Actualizar viajes',
                  color: Colors.grey.shade600,
                  onPressed: () {
                    dataProvider.refreshViajes();
                    setState(() {
                      _mapCenterOverride = null;
                    });
                  },
                ),
                DropdownButton<String>(
                  value: _selectedFilterRouteId,
                  hint: Text('Filtrar por Ruta',
                      style: GoogleFonts.poppins(fontSize: 14)),
                  underline: const SizedBox(),
                  icon: const Icon(Icons.filter_alt_outlined),
                  style: GoogleFonts.poppins(
                      color: Colors.grey.shade800, fontSize: 14),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Todas las Rutas'),
                    ),
                    ...routes.map((r) {
                      return DropdownMenuItem<String>(
                        value: r.id,
                        child: Text(r.name),
                      );
                    }),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedFilterRouteId = val;
                      _mapCenterOverride = null;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Listado lateral de unidades en viaje (30% de ancho en pantallas grandes)
              Expanded(
                flex: 3,
                child: Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.grey.shade50,
                          child: Text(
                            'Unidades Activas',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: const Color(0xFF1A1F2B),
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: viajesMostrados.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      'Sin viajes activos',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey.shade500,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: viajesMostrados.length,
                                  separatorBuilder: (context, index) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final viaje = viajesMostrados[index];
                                    final placaBus =
                                        viaje.vehiculoPlaca ?? viaje.idVehiculo;

                                    TransportRoute? r;
                                    try {
                                      r = routes.firstWhere((route) =>
                                          route.id == viaje.idRuta ||
                                          route.id == viaje.rutaNumero);
                                    } catch (_) {}
                                    final rName = viaje.rutaNombre ??
                                        r?.name ??
                                        'Ruta #${viaje.idRuta}';

                                    final isFocused =
                                        _mapCenterOverride != null &&
                                            _mapCenterOverride!.latitude ==
                                                viaje.lactitud &&
                                            _mapCenterOverride!.longitude ==
                                                viaje.longitud;

                                    return ListTile(
                                      dense: true,
                                      selected: isFocused,
                                      selectedTileColor: Colors.orange.shade50,
                                      leading: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: isFocused
                                            ? Colors.orange.shade700
                                            : Colors.orange.shade100,
                                        child: Icon(
                                          Icons.directions_bus,
                                          size: 16,
                                          color: isFocused
                                              ? Colors.white
                                              : Colors.orange.shade800,
                                        ),
                                      ),
                                      title: Text(
                                        placaBus.isNotEmpty
                                            ? placaBus
                                            : 'Sin placa',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: const Color(0xFF1A1F2B),
                                        ),
                                      ),
                                      subtitle: Text(
                                        rName,
                                        style:
                                            GoogleFonts.poppins(fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: const Icon(Icons.gps_fixed,
                                          size: 16, color: Colors.grey),
                                      onTap: () {
                                        setState(() {
                                          _mapCenterOverride = LatLng(
                                              viaje.lactitud, viaje.longitud);
                                        });
                                        _showViajeBottomSheet(
                                            context, viaje, r);
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Mapa (70% de ancho)
              Expanded(
                flex: 7,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: viajesMostrados.isEmpty
                        ? Stack(
                            children: [
                              DashboardMap(
                                center: center,
                                markers: const [],
                              ),
                              Center(
                                child: Container(
                                  margin: const EdgeInsets.all(24),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 18),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.directions_bus_outlined,
                                          size: 48,
                                          color: Colors.grey.shade400),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No hay buses en viaje activo',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Asigna una unidad a una ruta para iniciar un viaje',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : DashboardMap(
                            center: center,
                            markers: markers,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget reutilizable que muestra un mapa interactivo con marcadores.
/// Se encarga de renderizar el mapa usando Flutter Map y de mover la vista al centro indicado.
class DashboardMap extends StatefulWidget {
  final LatLng center;
  final List<Marker> markers;

  const DashboardMap({
    super.key,
    required this.center,
    required this.markers,
  });

  @override
  State<DashboardMap> createState() => _DashboardMapState();
}

/// Estado interno del mapa.
/// Mantiene el controlador del mapa y actualiza la vista cuando cambia el centro.
class _DashboardMapState extends State<DashboardMap> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  /// Reacciona a cambios en el centro del mapa.
  /// Cuando la posición objetivo cambia, la vista se desplaza para mostrarla.
  @override
  void didUpdateWidget(covariant DashboardMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.center != widget.center && mounted) {
      _mapController.move(widget.center, _mapController.camera.zoom);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: widget.center,
        initialZoom: 12.0,
        minZoom: 12.0,
        maxZoom: 20.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.tesis.admin',
          tileProvider: NetworkTileProvider(),
          keepBuffer:
              3, // Mantiene en memoria los mosaicos de hasta 3 niveles de zoom/posición anteriores
          panBuffer:
              2, // Suaviza la carga de imágenes en las esquinas al arrastrar
        ),
        MarkerLayer(
          markers: widget.markers,
        ),
      ],
    );
  }
}
