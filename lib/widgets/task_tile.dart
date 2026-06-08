import 'package:flutter/material.dart';

class TaskTile extends StatelessWidget {
  final Map<String, dynamic> task;
  final void Function(String)? onAction;

  const TaskTile({Key? key, required this.task, this.onAction})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = task['status'] as String? ?? '';

    Color statusColor() {
      switch (status) {
        case 'completed':
          return Colors.green;
        case 'in_progress':
          return Colors.orange;
        case 'pending':
          return Colors.blue;
        default:
          return Colors.grey;
      }
    }

    IconData statusIcon() {
      switch (status) {
        case 'completed':
          return Icons.check_circle;
        case 'in_progress':
          return Icons.pending;
        case 'pending':
          return Icons.schedule;
        default:
          return Icons.help;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor(),
          child: Icon(statusIcon(), color: Colors.white),
        ),
        title: Text(task['title'] ?? ''),
        subtitle: Text(
          'Priority: ${task['priority']} | Status: ${task['status']}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => onAction?.call(value),
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'in_progress',
              child: Text('Mark In Progress'),
            ),
            PopupMenuItem(value: 'completed', child: Text('Mark Completed')),
          ],
        ),
      ),
    );
  }
}
