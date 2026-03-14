import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/settings_provider.dart';
import '../../../core/theme/tavla_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Sound
          _buildSection(
            context,
            title: 'Oyun',
            children: [
              SwitchListTile(
                title: const Text('Ses Efektleri'),
                subtitle: const Text('Zar, taş hareketi ve bildirim sesleri'),
                value: settings.soundEnabled,
                activeTrackColor: TavlaTheme.brown,
                onChanged: (_) =>
                    ref.read(settingsProvider.notifier).toggleSound(),
                secondary: Icon(
                  settings.soundEnabled ? Icons.volume_up : Icons.volume_off,
                  color: TavlaTheme.brown,
                ),
              ),
              SwitchListTile(
                title: const Text('Titreşim'),
                subtitle: const Text('Dokunma geri bildirimi'),
                value: settings.hapticEnabled,
                activeTrackColor: TavlaTheme.brown,
                onChanged: (_) =>
                    ref.read(settingsProvider.notifier).toggleHaptic(),
                secondary: Icon(
                  settings.hapticEnabled
                      ? Icons.vibration
                      : Icons.smartphone,
                  color: TavlaTheme.brown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Board
          _buildSection(
            context,
            title: 'Tahta',
            children: [
              SwitchListTile(
                title: const Text('Hamle İpuçları'),
                subtitle:
                    const Text('Geçerli hamleleri yeşil ile göster'),
                value: settings.moveHintsEnabled,
                activeTrackColor: TavlaTheme.brown,
                onChanged: (_) =>
                    ref.read(settingsProvider.notifier).toggleMoveHints(),
                secondary: const Icon(Icons.lightbulb_outline,
                    color: TavlaTheme.brown),
              ),
              SwitchListTile(
                title: const Text('Point Numaraları'),
                subtitle: const Text('Tahta üzerinde 1-24 numaraları göster'),
                value: settings.pointNumbersEnabled,
                activeTrackColor: TavlaTheme.brown,
                onChanged: (_) =>
                    ref.read(settingsProvider.notifier).togglePointNumbers(),
                secondary: const Icon(Icons.numbers,
                    color: TavlaTheme.brown),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tutorial
          _buildSection(
            context,
            title: 'Yardım',
            children: [
              ListTile(
                leading:
                    const Icon(Icons.school, color: TavlaTheme.brown),
                title: const Text('Eğitimi Tekrar İzle'),
                subtitle: const Text('Tavla kurallarını öğren'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  ref.read(settingsProvider.notifier).resetTutorial();
                  context.go('/tutorial');
                },
              ),
              ListTile(
                leading: const Icon(Icons.smart_toy,
                    color: TavlaTheme.brown),
                title: const Text('Bot ile Pratik Yap'),
                subtitle: const Text('Yapay zekaya karşı oyna'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showBotDifficultyDialog(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context,
      {required String title, required List<Widget> children}) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: TavlaTheme.brown,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _showBotDifficultyDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zorluk Seviyesi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _difficultyTile(ctx, 'Kolay', 'Rastgele hamleler', 'easy'),
            _difficultyTile(ctx, 'Orta', 'Temel strateji', 'medium'),
            _difficultyTile(ctx, 'Zor', 'İleri seviye', 'hard'),
          ],
        ),
      ),
    );
  }

  Widget _difficultyTile(
      BuildContext context, String title, String subtitle, String level) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () {
        Navigator.pop(context);
        context.go('/bot', extra: {'difficulty': level});
      },
    );
  }
}
