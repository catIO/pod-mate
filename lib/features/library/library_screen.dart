import 'package:material_ui/material_ui.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.podcasts, size: 64),
            const SizedBox(height: 16),
            Text('No podcasts yet', style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Add one with its RSS feed URL', style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
