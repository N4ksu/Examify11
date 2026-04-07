import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/sync/sync_provider.dart';

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);

    if (syncState.isOnline && syncState.pendingCount == 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.cloud_done, color: Colors.green, size: 20),
          SizedBox(width: 4),
          Text(
            'Saved',
            style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (syncState.isSyncing)
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
          )
        else
          const Icon(Icons.cloud_sync, color: Colors.orange, size: 20),
        const SizedBox(width: 4),
        Text(
          '${syncState.pendingCount} pending',
          style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
