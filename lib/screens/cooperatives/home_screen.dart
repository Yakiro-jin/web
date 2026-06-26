import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/cooperative.dart';
import '../../models/system_user.dart';
import '../../models/route.dart';

import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/route_card.dart';
import '../../widgets/transport_unit_card.dart';
import '../routes/route_form_screen.dart';
import '../users/user_form_screen.dart';
import 'cooperative_form_screen.dart';
import 'driver_form_screen.dart';
import '../units/transport_unit_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  String? _selectedCooperativeId;
  String? _selectedFilterRouteId;
  int _activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    // TabController is initialized in didChangeDependencies or build when cooperatives count is known
  }

  void _initTabController() {
    if (_tabController == null) {
      _tabController = TabController(length: 5, vsync: this);
      _tabController!.addListener(() {
        if (_tabController!.index != _activeTabIndex) {
          setState(() {
            _activeTabIndex = _tabController!.index;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _showDeleteCooperativeDialog(BuildContext context, Cooperative cooperative) {
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

  void _showCooperativeSelectionDialog(BuildContext context, DataProvider dataProvider) {
    final cooperatives = dataProvider.cooperatives;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            'Seleccionar Cooperativa',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    backgroundColor: isSelected ? Colors.green.shade100 : Colors.grey.shade100,
                    child: Icon(
                      Icons.business,
                      color: isSelected ? Colors.green.shade800 : Colors.grey.shade700,
                    ),
                  ),
                  title: Text(
                    coop.name,
                    style: GoogleFonts.poppins(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.green) : null,
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

  void _showDeleteDriverDialog(BuildContext context, String driverId, String driverName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmar eliminación', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, dataProvider, child) {
        final cooperatives = dataProvider.cooperatives;

        if (cooperatives.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              title: Text(
                'Panel de Control',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
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
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add_business_rounded),
                      label: Text('Crear Cooperativa', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Handle selected cooperative
        _selectedCooperativeId ??= cooperatives.first.id;

        final matching = cooperatives.where((c) => c.id == _selectedCooperativeId);
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
                  const Icon(Icons.directions_bus, color: Colors.white, size: 28),
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
                  onPressed: () => _showCooperativeSelectionDialog(context, dataProvider),
                  icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
                  label: Text('Cambiar Cooperativa', style: GoogleFonts.poppins(color: Colors.white)),
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
                  icon: const Icon(Icons.add_business_rounded, color: Colors.white),
                  label: Text('Nueva Cooperativa', style: GoogleFonts.poppins(color: Colors.white)),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CooperativeFormScreen(cooperative: activeCooperative),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  label: Text('Editar Actual', style: GoogleFonts.poppins(color: Colors.white)),
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
                  unselectedLabelTextStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 12),
                  selectedLabelTextStyle: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  unselectedIconTheme: IconThemeData(color: Colors.grey.shade400),
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
                        builder: (context) => CooperativeFormScreen(cooperative: activeCooperative),
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
                        Text('Eliminar cooperativa actual', style: TextStyle(color: Colors.red)),
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
              child: Icon(Icons.route_outlined, size: 64, color: Colors.green.shade300),
            ),
            const SizedBox(height: 24),
            Text('No hay rutas registradas', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Text('Comienza agregando una nueva ruta', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade500)),
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
          childAspectRatio: 2.2,
        ),
        itemCount: routes.length,
        padding: const EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final route = routes[index];
          final unitCount = dataProvider.getUnitCountForRoute(route.id);
          return RouteCard(
            route: route,
            unitCount: unitCount,
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

        return RouteCard(
          route: route,
          unitCount: unitCount,
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
              child: Icon(Icons.directions_bus_outlined, size: 64, color: Colors.orange.shade300),
            ),
            const SizedBox(height: 24),
            Text('No hay buses registrados', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Text('Registra un bus y asígnale un chofer', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    Widget buildUnitCard(dynamic unit) {
      final matchingDrivers = dataProvider.drivers.where((d) => d.id == unit.driverId);
      final driverName = matchingDrivers.isNotEmpty ? '${matchingDrivers.first.name} ${matchingDrivers.first.lastName}' : null;
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
              child: Icon(Icons.people_outline_rounded, size: 64, color: Colors.blue.shade300),
            ),
            const SizedBox(height: 24),
            Text('No hay choferes registrados', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Text('Registra los choferes de la cooperativa aquí', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    Widget buildDriverCard(dynamic driver) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            radius: 24,
            child: Icon(Icons.person, color: Colors.blue.shade800, size: 28),
          ),
          title: Text(
            '${driver.name} ${driver.lastName}',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
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
                        const Icon(Icons.badge_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Flexible(child: Text('C.I. ${driver.id}', overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600))),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Flexible(child: Text(driver.phone, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600))),
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
                        const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Flexible(child: Text(driver.email, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600))),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cake_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Flexible(child: Text('${driver.age} años', overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600))),
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
                _showDeleteDriverDialog(context, driver.id, '${driver.name} ${driver.lastName}');
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
              child: Icon(Icons.people_outline_rounded, size: 64, color: Colors.teal.shade300),
            ),
            const SizedBox(height: 24),
            Text('No hay usuarios registrados', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            Text('Comienza agregando un nuevo usuario', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    Widget buildUserCard(SystemUser user) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: CircleAvatar(
            backgroundColor: Colors.teal.shade100,
            radius: 24,
            child: Icon(Icons.security, color: Colors.teal.shade800, size: 28),
          ),
          title: Text(
            '${user.nombre} ${user.apellido}',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('C.I. ${user.cedula}', style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(width: 12),
                    const Icon(Icons.admin_panel_settings_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(user.rol, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(user.correo, style: TextStyle(color: Colors.grey.shade600)),
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

  void _showDeleteUserDialog(BuildContext context, SystemUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirmar eliminación', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('¿Está seguro de eliminar al usuario "${user.nombre} ${user.apellido}"?'),
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

  Widget? _buildFAB(Cooperative cooperative) {
    if (_activeTabIndex == 0) {
      // Dashboard tab - no FAB
      return null;
    } else if (_activeTabIndex == 1) {
      return FloatingActionButton.extended(
        key: const ValueKey('fab_route'),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => RouteFormScreen(cooperativeId: cooperative.id),
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
              builder: (context) => TransportUnitFormScreen(cooperativeId: cooperative.id),
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
              builder: (context) => DriverFormScreen(cooperativeId: cooperative.id),
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

  Widget _buildDashboardTab(DataProvider dataProvider, Cooperative cooperative) {
    final routes = dataProvider.getRoutesByCooperative(cooperative.id);
    final units = dataProvider.getUnitsByCooperative(cooperative.id);

    // Filter units based on selection
    final filteredUnits = units.where((u) {
      if (_selectedFilterRouteId == null) return true;
      return u.routeId == _selectedFilterRouteId;
    }).toList();

    // Determine map center
    LatLng center = const LatLng(10.4806, -66.9036); // Caracas
    if (_selectedFilterRouteId != null) {
      try {
        final selectedRoute = routes.firstWhere((r) => r.id == _selectedFilterRouteId);
        if (selectedRoute.stops.isNotEmpty) {
          center = LatLng(selectedRoute.stops.first.latitude, selectedRoute.stops.first.longitude);
        }
      } catch (_) {}
    } else if (routes.isNotEmpty) {
      // Find first route with stops
      LatLng? foundCenter;
      for (final r in routes) {
        if (r.stops.isNotEmpty) {
          foundCenter = LatLng(r.stops.first.latitude, r.stops.first.longitude);
          break;
        }
      }
      if (foundCenter != null) {
        center = foundCenter;
      }
    }

    // Build markers
    final markers = filteredUnits.map((unit) {
      TransportRoute? unitRoute;
      if (unit.routeId != null) {
        try {
          unitRoute = routes.firstWhere((r) => r.id == unit.routeId);
        } catch (_) {}
      }

      LatLng pos;
      if (unitRoute != null && unitRoute.stops.isNotEmpty) {
        final stopIndex = unit.plate.hashCode % unitRoute.stops.length;
        final stop = unitRoute.stops[stopIndex];
        // small deterministic offset so they don't overlap
        final offsetLat = (unit.plate.hashCode % 7 - 3) * 0.0008;
        final offsetLng = (unit.plate.hashCode % 5 - 2) * 0.0008;
        pos = LatLng(stop.latitude + offsetLat, stop.longitude + offsetLng);
      } else {
        final offsetLat = (unit.plate.hashCode % 11 - 5) * 0.005;
        final offsetLng = (unit.plate.hashCode % 7 - 3) * 0.005;
        pos = LatLng(center.latitude + offsetLat, center.longitude + offsetLng);
      }

      return Marker(
        point: pos,
        width: 40,
        height: 40,
        child: Tooltip(
          message: 'Modelo: ${unit.model}\nPlaca: ${unit.plate}\nRuta: ${unitRoute?.name ?? 'No asignada'}',
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.directions_bus,
              color: unitRoute != null ? Colors.orange.shade800 : Colors.grey.shade600,
              size: 24,
            ),
          ),
        ),
      );
    }).toList();

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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                const Spacer(),
                DropdownButton<String>(
                  value: _selectedFilterRouteId,
                  hint: Text('Filtrar por Ruta', style: GoogleFonts.poppins(fontSize: 14)),
                  underline: const SizedBox(),
                  icon: const Icon(Icons.filter_alt_outlined),
                  style: GoogleFonts.poppins(color: Colors.grey.shade800, fontSize: 14),
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
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
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
                  MarkerLayer(
                    markers: markers,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
