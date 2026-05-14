import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class {{container_name.pascalCase()}}Container extends StatefulWidget {
  const {{container_name.pascalCase()}}Container({super.key});

  @override
  State<{{container_name.pascalCase()}}Container> createState() => _{{container_name.pascalCase()}}ContainerState();
}

class _{{container_name.pascalCase()}}ContainerState extends State<{{container_name.pascalCase()}}Container> {
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
          body: Stack(),
        );
      },
    );
  }
}
