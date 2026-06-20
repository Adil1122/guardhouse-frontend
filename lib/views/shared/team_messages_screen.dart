import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:security_app/constants/app_constants.dart';
import 'package:security_app/constants/typography.dart';
import 'package:security_app/viewmodels/admin_viewmodel.dart';
import 'package:security_app/viewmodels/supervisor_viewmodel.dart';
import 'package:security_app/viewmodels/worker_viewmodel.dart';
import 'package:security_app/widgets/worker_panel_components.dart';

enum TeamMessageRole { admin, supervisor, worker }

class TeamMessagesScreen extends StatefulWidget {
  final TeamMessageRole role;
  const TeamMessagesScreen({super.key, required this.role});

  @override
  State<TeamMessagesScreen> createState() => _TeamMessagesScreenState();
}

class _TeamMessagesScreenState extends State<TeamMessagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    switch (widget.role) {
      case TeamMessageRole.admin:
        context.read<AdminViewModel>().loadTeamMessages();
      case TeamMessageRole.supervisor:
        context.read<SupervisorViewModel>().loadTeamMessages();
      case TeamMessageRole.worker:
        context.read<WorkerViewModel>().loadTeamMessages();
    }
  }

  List<Map<String, dynamic>> _messages() {
    switch (widget.role) {
      case TeamMessageRole.admin:
        return context.watch<AdminViewModel>().teamMessages;
      case TeamMessageRole.supervisor:
        return context.watch<SupervisorViewModel>().teamMessages;
      case TeamMessageRole.worker:
        return context.watch<WorkerViewModel>().teamMessages;
    }
  }

  bool get _isAdmin => widget.role == TeamMessageRole.admin;

  Future<void> _showComposeDialog() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => const _ComposeDialog(),
    );

    if (result == null || !mounted) return;
    final ok = await context.read<AdminViewModel>().sendTeamMessage(
          result['title']!,
          result['body']!,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Message sent to all staff' : 'Failed to send message'),
          backgroundColor: ok ? AppColors.success : AppColors.error,
        ),
      );
    }
  }

  Future<void> _confirmDelete(String id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Message'),
        content: Text('Delete "$title"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<AdminViewModel>().deleteTeamMessage(id);
  }

  @override
  Widget build(BuildContext context) {
    final messages = _messages();

    return WorkerPanelScaffold(
      title: 'Team Messages',
      actions: _isAdmin
          ? [
              IconButton(
                onPressed: _showComposeDialog,
                icon: const Icon(Icons.edit_square, color: Colors.white),
                tooltip: 'New Message',
              ),
            ]
          : const [],
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: messages.isEmpty
            ? const WorkerStatusBanner(
                title: 'No Messages',
                subtitle: 'No team messages have been sent yet.',
                icon: Icons.campaign_outlined,
                variant: WorkerStatusVariant.info,
              )
            : ListView.builder(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                itemCount: messages.length,
                itemBuilder: (context, i) {
                  final msg = messages[i];
                  return _MessageCard(
                    message: msg,
                    showDelete: _isAdmin,
                    onDelete: () => _confirmDelete(
                      msg['id'].toString(),
                      msg['title']?.toString() ?? '',
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool showDelete;
  final VoidCallback onDelete;

  const _MessageCard({
    required this.message,
    required this.showDelete,
    required this.onDelete,
  });

  String _formatDate(dynamic value) {
    if (value == null) return '';
    try {
      final dt = DateTime.parse(value.toString()).toLocal();
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WorkerPanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38.sp,
                height: 38.sp,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(Icons.campaign_outlined, size: 20.sp, color: AppColors.primary),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message['title']?.toString() ?? '',
                      style: AppTypography.body().copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'From: ${message['created_by'] ?? 'Admin'}  ·  ${_formatDate(message['created_at'])}',
                      style: AppTypography.body().copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              if (showDelete)
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline, size: 20.sp, color: AppColors.error),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              message['body']?.toString() ?? '',
              style: AppTypography.body().copyWith(fontSize: 13.sp),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComposeDialog extends StatefulWidget {
  const _ComposeDialog();

  @override
  State<_ComposeDialog> createState() => _ComposeDialogState();
}

class _ComposeDialogState extends State<_ComposeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Team Message'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Title',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleCtrl,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: Color(0xFF111827), fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Enter message title',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              const Text(
                'Message',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _bodyCtrl,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(color: Color(0xFF111827), fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Type your message here...',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'title': _titleCtrl.text.trim(),
                'body': _bodyCtrl.text.trim(),
              });
            }
          },
          icon: const Icon(Icons.send),
          label: const Text('Send'),
        ),
      ],
    );
  }
}
