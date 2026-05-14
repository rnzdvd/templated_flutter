import 'package:flutter/material.dart';

class {{component_name.pascalCase()}}View extends StatefulWidget {
  const {{component_name.pascalCase()}}View({super.key});

  @override
  State<{{component_name.pascalCase()}}View> createState() => _{{component_name.pascalCase()}}ViewState();
}

class _{{component_name.pascalCase()}}ViewState extends State<{{component_name.pascalCase()}}View> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Center(child: Text('{{component_name.pascalCase()}}')),
      ),
    );
  }
}