import 'package:{{package_name}}/src/{{module_name}}/ui/{{component_name}}/{{component_name}}.view.dart';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class {{component_name.pascalCase()}}Container extends StatefulWidget {
  const {{component_name.pascalCase()}}Container({super.key});

  @override
  State<{{component_name.pascalCase()}}Container> createState() => _{{component_name.pascalCase()}}ContainerState();
}

class _{{component_name.pascalCase()}}ContainerState extends State<{{component_name.pascalCase()}}Container> {
  @override
  void initState() {
    super.initState();
    // Defer execution until after the first frame is rendered.
    // This ensures that any context-dependent or reactive logic runs
    // after the widget is fully mounted and avoids build-time side effects.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      () async {
        // Perform initialization logic here (e.g.,fetching data from API, executing async tasks)
      }();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        return Scaffold(
          body: Stack(
            children: [
              Center(child: {{component_name.pascalCase()}}View()),
            ],
          ),
        );
      },
    );
  }
}
