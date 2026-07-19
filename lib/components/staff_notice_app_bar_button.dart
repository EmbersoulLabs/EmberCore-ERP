import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/staff_notices_record.dart';
import '/backend/schema/users_record.dart';
import '/backend/staff_notice_helpers.dart';
import '/backend/user_query_helpers.dart';
import '/components/ember_app_bar.dart';
import '/l10n/tr.dart';
import '/theme/ember_brand.dart';

/// Bell icon with unread badge and notice list for dashboard app bars.
class StaffNoticeAppBarButton extends StatefulWidget {
  const StaffNoticeAppBarButton({
    super.key,
    this.iconColor = Colors.white,
    this.compact = false,
  });

  const StaffNoticeAppBarButton.onPrimary({
    super.key,
    this.compact = false,
  }) : iconColor = Colors.white;

  final Color iconColor;
  final bool compact;

  @override
  State<StaffNoticeAppBarButton> createState() =>
      _StaffNoticeAppBarButtonState();
}

class _StaffNoticeAppBarButtonState extends State<StaffNoticeAppBarButton> {
  DocumentReference? _recipientRef;

  @override
  void initState() {
    super.initState();
    _resolveRecipient();
  }

  Future<void> _resolveRecipient() async {
    if (!loggedIn) {
      return;
    }
    final profile = await resolveCurrentUserProfile();
    if (!mounted) {
      return;
    }
    final uid = currentUserUid.isNotEmpty
        ? currentUserUid
        : (profile?.uid.isNotEmpty == true ? profile!.uid : null);
    setState(() {
      _recipientRef =
          uid != null && uid.isNotEmpty ? UsersRecord.collection.doc(uid) : null;
    });
  }

  void _openNoticeSheet() {
    if (_recipientRef == null) {
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _StaffNoticeSheet(
          recipientRef: _recipientRef!,
          parentContext: context,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_recipientRef == null) {
      final size = widget.compact
          ? emberAppBarIconButtonSize(context)
          : 44.0;
      return IconButton(
        onPressed: null,
        padding: widget.compact ? EdgeInsets.zero : null,
        constraints: BoxConstraints(minWidth: size, minHeight: size),
        visualDensity:
            widget.compact ? VisualDensity.compact : VisualDensity.standard,
        icon: Icon(
          Icons.notifications_outlined,
          color: widget.iconColor,
          size: emberAppBarIconSize(context),
        ),
      );
    }

    return StreamBuilder<List<StaffNoticesRecord>>(
      stream: streamStaffNoticesForRecipient(_recipientRef!),
      builder: (context, snapshot) {
        final notices = snapshot.data ?? const [];
        final unread =
            notices.where((notice) => isStaffNoticeUnread(notice)).length;

        final size = widget.compact
            ? emberAppBarIconButtonSize(context)
            : 44.0;

        return IconButton(
          tooltip: tr(context, 'notice.tooltip'),
          padding: widget.compact ? EdgeInsets.zero : null,
          constraints: BoxConstraints(minWidth: size, minHeight: size),
          visualDensity:
              widget.compact ? VisualDensity.compact : VisualDensity.standard,
          onPressed: _openNoticeSheet,
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text(unread > 99 ? '99+' : '$unread'),
            child: Icon(
              unread > 0
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_outlined,
              color: widget.iconColor,
              size: emberAppBarIconSize(context),
            ),
          ),
        );
      },
    );
  }
}

class _StaffNoticeSheet extends StatefulWidget {
  const _StaffNoticeSheet({
    required this.recipientRef,
    required this.parentContext,
  });

  final DocumentReference recipientRef;
  final BuildContext parentContext;

  @override
  State<_StaffNoticeSheet> createState() => _StaffNoticeSheetState();
}

class _StaffNoticeSheetState extends State<_StaffNoticeSheet> {
  var _clearing = false;

  Future<void> _clearUnreadNotices(List<StaffNoticesRecord> notices) async {
    if (_clearing) {
      return;
    }
    setState(() => _clearing = true);
    try {
      final cleared = await markAllStaffNoticesRead(notices);
      if (!mounted) {
        return;
      }
      if (cleared > 0 && widget.parentContext.mounted) {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(content: Text(tr(context, 'notice.sheet.cleared'))),
        );
      }
    } catch (_) {
      if (mounted && widget.parentContext.mounted) {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'notice.sheet.clearFailed')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _clearing = false);
      }
    }
  }

  Future<void> _openNotice(StaffNoticesRecord notice) async {
    // Keep the notice in the list; only mark read so the badge updates.
    // Do not clear / delete on open.
    Navigator.of(context).pop();
    if (isStaffNoticeUnread(notice)) {
      try {
        await markStaffNoticeRead(notice.reference);
      } catch (_) {
        // Navigation should still proceed if the read stamp fails.
      }
    }
    if (!widget.parentContext.mounted) {
      return;
    }
    await openStaffNoticeTarget(widget.parentContext, notice);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        decoration: const BoxDecoration(
          color: EmberBrand.card,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(EmberBrand.radiusLg),
          ),
        ),
        child: StreamBuilder<List<StaffNoticesRecord>>(
          stream: streamStaffNoticesForRecipient(widget.recipientRef),
          builder: (context, snapshot) {
            final notices = _sortedNotices(snapshot.data ?? const []);
            final unreadCount =
                notices.where((notice) => isStaffNoticeUnread(notice)).length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          tr(context, 'notice.sheet.title'),
                          style: GoogleFonts.interTight(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: EmberBrand.navy,
                          ),
                        ),
                      ),
                      if (unreadCount > 0)
                        TextButton(
                          onPressed: _clearing
                              ? null
                              : () => _clearUnreadNotices(notices),
                          child: Text(
                            _clearing
                                ? tr(context, 'notice.sheet.clearing')
                                : tr(context, 'notice.sheet.clear'),
                            style: GoogleFonts.inter(
                              color: EmberBrand.navy,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (notices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      tr(context, 'notice.sheet.empty'),
                      style: GoogleFonts.inter(
                        color: EmberBrand.textSecondary,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        12,
                        0,
                        12,
                        12 + MediaQuery.paddingOf(context).bottom,
                      ),
                      itemCount: notices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final notice = notices[index];
                        return _DismissibleNoticeTile(
                          notice: notice,
                          onTap: () => _openNotice(notice),
                          onDeleteFailed: () {
                            if (!widget.parentContext.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(widget.parentContext)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  tr(context, 'notice.sheet.deleteFailed'),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

List<StaffNoticesRecord> _sortedNotices(List<StaffNoticesRecord> notices) {
  final sorted = notices.toList(growable: false);
  sorted.sort((a, b) {
    final aUnread = isStaffNoticeUnread(a);
    final bUnread = isStaffNoticeUnread(b);
    if (aUnread != bUnread) {
      return aUnread ? -1 : 1;
    }
    final aTime = a.createdTime ?? DateTime.fromMillisecondsSinceEpoch(0);
    final bTime = b.createdTime ?? DateTime.fromMillisecondsSinceEpoch(0);
    return bTime.compareTo(aTime);
  });
  return sorted;
}

class _DismissibleNoticeTile extends StatelessWidget {
  const _DismissibleNoticeTile({
    required this.notice,
    required this.onTap,
    required this.onDeleteFailed,
  });

  final StaffNoticesRecord notice;
  final VoidCallback onTap;
  final VoidCallback onDeleteFailed;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(notice.reference.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: EmberBrand.error,
          borderRadius: BorderRadius.circular(EmberBrand.radiusMd),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        try {
          await deleteStaffNotice(notice.reference);
          return true;
        } catch (_) {
          onDeleteFailed();
          return false;
        }
      },
      child: _NoticeTile(
        notice: notice,
        onTap: onTap,
      ),
    );
  }
}

class _NoticeTile extends StatelessWidget {
  const _NoticeTile({
    required this.notice,
    required this.onTap,
  });

  final StaffNoticesRecord notice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = isStaffNoticeUnread(notice);
    return Material(
      color: unread
          ? EmberBrand.navy.withValues(alpha: 0.06)
          : EmberBrand.background,
      borderRadius: BorderRadius.circular(EmberBrand.radiusMd),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EmberBrand.radiusMd),
          side: const BorderSide(color: EmberBrand.border),
        ),
        title: Text(
          staffNoticeTitle(notice, context),
          style: GoogleFonts.interTight(
            fontWeight: FontWeight.w600,
            color: unread ? EmberBrand.textPrimary : EmberBrand.textSecondary,
          ),
        ),
        subtitle: Text(
          staffNoticeDisplayBody(notice, context),
          style: GoogleFonts.inter(
            color: EmberBrand.textSecondary,
            fontSize: 13,
          ),
        ),
        isThreeLine: true,
        trailing: unread
            ? const Icon(
                Icons.fiber_manual_record,
                size: 10,
                color: EmberBrand.navy,
              )
            : null,
      ),
    );
  }
}
