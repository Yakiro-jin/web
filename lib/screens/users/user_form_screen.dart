import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/system_user.dart';
import '../../providers/data_provider.dart';

/// Formulario para crear o editar un usuario del sistema.
/// Recopila datos personales, rol, correo y contraseña, permitiendo administrar
/// los accesos del panel de gestión de forma centralizada.
class UserFormScreen extends StatefulWidget {
  final SystemUser? user;

  const UserFormScreen({
    super.key,
    this.user,
  });

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _cedulaController;
  late TextEditingController _correoController;
  late TextEditingController _passwordController;
  String _selectedRol = 'Administrador';
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> _roles = ['Administrador', 'Fiscal', 'Chofer'];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.user?.nombre ?? '');
    _apellidoController =
        TextEditingController(text: widget.user?.apellido ?? '');
    _cedulaController = TextEditingController(text: widget.user?.cedula ?? '');
    _correoController = TextEditingController(text: widget.user?.correo ?? '');
    _passwordController =
        TextEditingController(text: widget.user?.password ?? '');
    if (widget.user != null && _roles.contains(widget.user!.rol)) {
      _selectedRol = widget.user!.rol;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _cedulaController.dispose();
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Guarda un usuario nuevo o actualiza uno existente tras validar el formulario.
  /// El método prepara el objeto de usuario y lo envía al provider para persistirlo.
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final dataProvider = context.read<DataProvider>();

    final nombre = _nombreController.text.trim();
    final apellido = _apellidoController.text.trim();
    final cedula = _cedulaController.text.trim();
    final correo = _correoController.text.trim();
    final password =
        _passwordController.text.isNotEmpty ? _passwordController.text : '123';

    if (widget.user == null) {
      // Create new
      final newUser = SystemUser(
        id: const Uuid().v4(),
        nombre: nombre,
        apellido: apellido,
        cedula: cedula,
        rol: _selectedRol,
        correo: correo,
        password: password,
      );
      await dataProvider.addSystemUser(newUser);
    } else {
      // Update existing
      final updatedUser = SystemUser(
        id: widget.user!.id,
        nombre: nombre,
        apellido: apellido,
        cedula: cedula,
        rol: _selectedRol,
        correo: correo,
        password: password,
      );
      await dataProvider.updateSystemUser(updatedUser);
    }

    if (!mounted) return;

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.user == null
            ? 'Usuario registrado exitosamente'
            : 'Usuario actualizado exitosamente'),
      ),
    );
  }

  /// Construye la interfaz del formulario de usuarios con campos claros y un botón de acción.
  /// Se organiza para capturar información básica del usuario y su rol dentro del sistema.
  @override
  Widget build(BuildContext context) {
    final isEditing = widget.user != null;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          isEditing ? 'Editar Usuario' : 'Nuevo Usuario',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF1A1F2B),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle(
                      'Información del Usuario', Icons.person_add_alt_1),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _nombreController,
                            label: 'Nombre',
                            icon: Icons.person,
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Campo requerido' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _apellidoController,
                            label: 'Apellido',
                            icon: Icons.person_outline,
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Campo requerido' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _cedulaController,
                            label: 'Cédula de identidad',
                            icon: Icons.badge_outlined,
                            enabled: !isEditing,
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Campo requerido' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _correoController,
                            label: 'Correo Electrónico',
                            icon: Icons.email,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Campo requerido';
                              }
                              if (!v.contains('@')) return 'Email inválido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedRol,
                            decoration: InputDecoration(
                              labelText: 'Rol',
                              prefixIcon: const Icon(Icons.security,
                                  size: 22, color: Color(0xFF1A1F2B)),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            items: _roles.map((rol) {
                              return DropdownMenuItem(
                                value: rol,
                                child: Text(rol, style: GoogleFonts.poppins()),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedRol = val;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Contraseña (por defecto 123)',
                              prefixIcon: const Icon(Icons.lock_outline,
                                  size: 22, color: Color(0xFF1A1F2B)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey.shade600,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade300),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
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
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            isEditing ? 'Guardar Cambios' : 'Registrar Usuario',
                            style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: const Color(0xFF1A1F2B), size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
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
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: formatters,
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
          borderSide: BorderSide(color: const Color(0xFF1A1F2B), width: 2),
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
