import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';

class AppTile extends StatelessWidget {
  final Application app;
  final bool isLocked;
  final Function(bool) onToggle;

  const AppTile({
    super.key,
    required this.app,
    required this.isLocked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: app is ApplicationWithIcon
          ? Image.memory((app as ApplicationWithIcon).icon, width: 40, height: 40)
          : const Icon(Icons.android, size: 40),
      title: Text(app.appName),
      subtitle: Text(app.packageName),
      trailing: Switch(
        value: isLocked,
        onChanged: onToggle,
      ),
    );
  }
}
