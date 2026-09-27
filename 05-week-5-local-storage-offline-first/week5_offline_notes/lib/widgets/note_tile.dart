import 'package:flutter/material.dart';
import '../data/local/note.dart';

class NoteTile extends StatelessWidget {
  const NoteTile({
    super.key,
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          Expanded(child: Text(note.title)),
          if (note.dirty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'belum tersinkron',
                style: TextStyle(fontSize: 11, color: Colors.orange.shade900),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(note.dirty ? 'belum disync' : 'tersimpan'),
      onTap: onTap,
      trailing: IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
    );
  }
}