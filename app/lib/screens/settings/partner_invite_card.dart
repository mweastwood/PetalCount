import 'package:flutter/material.dart';

import '../../logic/logic.dart';

class PartnerInviteCard extends StatefulWidget {
  const PartnerInviteCard({super.key});

  @override
  State<PartnerInviteCard> createState() => _PartnerInviteCardState();
}

class _PartnerInviteCardState extends State<PartnerInviteCard> {
  final _inviteEmailController = TextEditingController();
  bool _isInviting = false;
  String _inviteStatus = '';

  @override
  void dispose() {
    _inviteEmailController.dispose();
    super.dispose();
  }

  Future<void> _sendInvite() async {
    final email = _inviteEmailController.text.trim();
    if (email.isEmpty) return;

    setState(() {
      _isInviting = true;
      _inviteStatus = '';
    });

    try {
      await Services.db.invitePartner(email);
      setState(() {
        _inviteStatus = 'Invitation successfully sent to $email!';
        _inviteEmailController.clear();
      });
    } catch (e) {
      setState(() {
        _inviteStatus =
            'Error: ${e.toString().replaceFirst("Exception: ", "")}';
      });
    } finally {
      setState(() {
        _isInviting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Invite Partner to Collaborate',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your spouse\'s email address. Once they sign up and log in, they will be prompted to join this cycle chart and can view or log observations in real time.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _inviteEmailController,
          decoration: const InputDecoration(
            labelText: 'Partner Email Address',
            border: OutlineInputBorder(),
            suffixIcon: Icon(Icons.mail_outline),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        _isInviting
            ? const Center(child: CircularProgressIndicator())
            : FilledButton(
                onPressed: _sendInvite,
                child: const Text('Send Collaboration Invite'),
              ),
        if (_inviteStatus.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            _inviteStatus,
            style: TextStyle(
              color: _inviteStatus.startsWith('Error')
                  ? Colors.red
                  : Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
