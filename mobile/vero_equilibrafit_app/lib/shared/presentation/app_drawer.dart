import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) => NavigationDrawer(
    children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(28, 28, 16, 12),
        child: Text(
          'VeroEqulibraFit+',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      _item(context, Icons.dashboard_outlined, 'Dashboard', '/'),
      _item(context, Icons.fitness_center, 'Treinos', '/training'),
      _item(context, Icons.restaurant_outlined, 'Alimentação', '/nutrition'),
      _item(context, Icons.water_drop_outlined, 'Hábitos', '/habits'),
      _item(context, Icons.monitor_weight_outlined, 'Evolução', '/measurements'),
      _item(context, Icons.auto_awesome_outlined, 'Coach', '/coach'),
    ],
  );

  Widget _item(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) => ListTile(
    leading: Icon(icon),
    title: Text(label),
    onTap: () {
      Navigator.pop(context);
      context.go(route);
    },
  );
}
