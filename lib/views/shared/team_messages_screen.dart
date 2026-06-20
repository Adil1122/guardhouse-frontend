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
                    role: widget.role,
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

class _MessageCard extends StatefulWidget {
  final Map<String, dynamic> message;
  final TeamMessageRole role;
  final bool showDelete;
  final VoidCallback onDelete;

  const _MessageCard({
    required this.message,
    required this.role,
    required this.showDelete,
    required this.onDelete,
  });

  @override
  State<_MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<_MessageCard> {
  bool _expanded = false;
  final _replyCtrl = TextEditingController();
  bool _sending = false;

  String get _messageId => widget.message['id'].toString();
  bool get _isAdmin => widget.role == TeamMessageRole.admin;

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() => _expanded = !_expanded);
    if (!_expanded) return;
    if (_isAdmin) {
      context.read<AdminViewModel>().loadMessageThreads(_messageId);
    } else if (widget.role == TeamMessageRole.supervisor) {
      context.read<SupervisorViewModel>().loadMessageReplies(_messageId);
    } else {
      context.read<WorkerViewModel>().loadMessageReplies(_messageId);
    }
  }

  Future<void> _sendMyReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    final ok = widget.role == TeamMessageRole.supervisor
        ? await context.read<SupervisorViewModel>().sendMessageReply(_messageId, text)
        : await context.read<WorkerViewModel>().sendMessageReply(_messageId, text);
    if (mounted) {
      setState(() => _sending = false);
      if (ok) {
        _replyCtrl.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send reply'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
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
              if (widget.showDelete)
                IconButton(
                  onPressed: widget.onDelete,
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
          SizedBox(height: 8.h),
          InkWell(
            onTap: _toggleExpand,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Row(
                children: [
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18.sp,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    _isAdmin ? 'Replies' : 'Reply',
                    style: AppTypography.body().copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            SizedBox(height: 6.h),
            if (_isAdmin)
              _AdminThreadsSection(messageId: _messageId)
            else
              _MyReplyThread(role: widget.role, messageId: _messageId),
            if (!_isAdmin) ...[
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyCtrl,
                      style: const TextStyle(color: Color(0xFF111827), fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Type a reply to admin...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.r)),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  _sending
                      ? SizedBox(
                          width: 36.sp,
                          height: 36.sp,
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          onPressed: _sendMyReply,
                          icon: Icon(Icons.send, color: AppColors.primary, size: 22.sp),
                        ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ReplyBubble extends StatelessWidget {
  final String senderName;
  final String body;
  final String createdAt;
  final bool isAdminSender;

  const _ReplyBubble({
    required this.senderName,
    required this.body,
    required this.createdAt,
    required this.isAdminSender,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isAdminSender ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(maxWidth: 0.78.sw),
        margin: EdgeInsets.symmetric(vertical: 4.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isAdminSender ? const Color(0xFFE5E7EB) : AppColors.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              senderName,
              style: AppTypography.body().copyWith(fontSize: 11.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 2.h),
            Text(body, style: AppTypography.body().copyWith(fontSize: 13.sp)),
            SizedBox(height: 2.h),
            Text(
              _formatDate(createdAt),
              style: AppTypography.body().copyWith(fontSize: 9.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyReplyThread extends StatelessWidget {
  final TeamMessageRole role;
  final String messageId;

  const _MyReplyThread({required this.role, required this.messageId});

  @override
  Widget build(BuildContext context) {
    final replies = role == TeamMessageRole.supervisor
        ? context.watch<SupervisorViewModel>().repliesFor(messageId)
        : context.watch<WorkerViewModel>().repliesFor(messageId);

    if (replies.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Text(
          'No replies yet. Send a message to admin below.',
          style: AppTypography.body().copyWith(fontSize: 12.sp, color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: replies.map((r) {
        return _ReplyBubble(
          senderName: (r['is_admin'] == true) ? 'Admin' : (r['sender_name']?.toString() ?? 'You'),
          body: r['body']?.toString() ?? '',
          createdAt: r['created_at']?.toString() ?? '',
          isAdminSender: r['is_admin'] == true,
        );
      }).toList(),
    );
  }
}

class _AdminThreadsSection extends StatelessWidget {
  final String messageId;

  const _AdminThreadsSection({required this.messageId});

  @override
  Widget build(BuildContext context) {
    final threads = context.watch<AdminViewModel>().threadsFor(messageId);

    if (threads.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Text(
          'No replies from staff yet.',
          style: AppTypography.body().copyWith(fontSize: 12.sp, color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: threads.map((t) {
        return _AdminThreadCard(
          messageId: messageId,
          threadUserId: t['thread_user_id'] as int,
          threadUserName: t['thread_user_name']?.toString() ?? 'Unknown',
          replies: List<Map<String, dynamic>>.from(t['replies'] ?? []),
        );
      }).toList(),
    );
  }
}

class _AdminThreadCard extends StatefulWidget {
  final String messageId;
  final int threadUserId;
  final String threadUserName;
  final List<Map<String, dynamic>> replies;

  const _AdminThreadCard({
    required this.messageId,
    required this.threadUserId,
    required this.threadUserName,
    required this.replies,
  });

  @override
  State<_AdminThreadCard> createState() => _AdminThreadCardState();
}

class _AdminThreadCardState extends State<_AdminThreadCard> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    final ok = await context.read<AdminViewModel>().sendThreadReply(
          widget.messageId,
          widget.threadUserId,
          text,
        );
    if (mounted) {
      setState(() => _sending = false);
      if (ok) {
        _ctrl.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send reply'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.threadUserName,
            style: AppTypography.body().copyWith(fontSize: 12.sp, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 4.h),
          ...widget.replies.map((r) => _ReplyBubble(
                senderName: (r['is_admin'] == true) ? 'Admin' : (r['sender_name']?.toString() ?? widget.threadUserName),
                body: r['body']?.toString() ?? '',
                createdAt: r['created_at']?.toString() ?? '',
                isAdminSender: r['is_admin'] == true,
              )),
          SizedBox(height: 6.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: const TextStyle(color: Color(0xFF111827), fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Reply to ${widget.threadUserName}...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18.r)),
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              _sending
                  ? SizedBox(
                      width: 32.sp,
                      height: 32.sp,
                      child: const Padding(
                        padding: EdgeInsets.all(7.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      onPressed: _send,
                      icon: Icon(Icons.send, color: AppColors.primary, size: 20.sp),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
            ],
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
