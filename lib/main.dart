import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hydropinn_flutter_web/core/theme/dark_theme.dart';
import 'package:hydropinn_flutter_web/features/hydro_dashboard/data/models/hydro_models.dart';
import 'package:hydropinn_flutter_web/features/hydro_dashboard/presentation/state_management/hydro_controller.dart';
import 'package:hydropinn_flutter_web/features/hydro_dashboard/presentation/screens/hydro_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HydroPinnBootstrap());
}

class HydroPinnBootstrap extends StatefulWidget {
  const HydroPinnBootstrap({super.key});

  @override
  State<HydroPinnBootstrap> createState() => _HydroPinnBootstrapState();
}

class _HydroPinnBootstrapState extends State<HydroPinnBootstrap> {
  HydroController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final rawJson =
          await rootBundle.loadString('assets/data/hydro_data.json');
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      final hydroData = HydroData.fromJson(decoded);
      setState(() {
        _controller = HydroController(hydroData);
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1440, 900),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MaterialApp(
        title: 'HydroPINN — Water Decision Platform',
        debugShowCheckedModeBanner: false,
        theme: darkTheme,
        home: child,
      ),
      child: _error != null
          ? Scaffold(
              backgroundColor: const Color(0xFF060A12),
              body: Center(
                child: Text(
                  'Failed to load hydro_data.json: $_error',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            )
          : _controller == null
              ? const Scaffold(
                  backgroundColor: Color(0xFF060A12),
                  body: Center(
                    child: CircularProgressIndicator(color: Color(0xFF22D3EE)),
                  ),
                )
              : HydroAppShell(ctrl: _controller!),
    );
  }
}
