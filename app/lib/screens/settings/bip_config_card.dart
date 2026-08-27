import 'package:flutter/material.dart';

import '../../logic/logic.dart';

class BipConfigCard extends StatefulWidget {
  final Cycle activeCycle;

  const BipConfigCard({super.key, required this.activeCycle});

  @override
  State<BipConfigCard> createState() => _BipConfigCardState();
}

class _BipConfigCardState extends State<BipConfigCard> {
  final List<String> _availableBipOptions = ['6C', '6Y', '8C', '8Y'];
  late List<String> _selectedBips;

  @override
  void initState() {
    super.initState();
    _selectedBips = List<String>.from(widget.activeCycle.bipCodes);
  }

  @override
  void didUpdateWidget(covariant BipConfigCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeCycle.id != widget.activeCycle.id ||
        oldWidget.activeCycle.bipCodes != widget.activeCycle.bipCodes) {
      _selectedBips = List<String>.from(widget.activeCycle.bipCodes);
    }
  }

  Future<void> _toggleBipCode(String code, bool selected) async {
    setState(() {
      if (selected) {
        _selectedBips.add(code);
      } else {
        _selectedBips.remove(code);
      }
    });

    // Save to database which triggers automatic recalculation of stamps!
    await Services.db.updateBipCodes(widget.activeCycle.id, _selectedBips);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Base Infertile Pattern (BIP) Config',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Define which cervical mucus VDRS codes constitute the wife\'s standard BIP. The system will automatically paint matching days with Yellow stamps (denoting infertility) instead of White Baby stamps.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: _availableBipOptions.map((code) {
            final isSelected = _selectedBips.contains(code);
            return FilterChip(
              label: Text(code),
              selected: isSelected,
              onSelected: (selected) => _toggleBipCode(code, selected),
            );
          }).toList(),
        ),
      ],
    );
  }
}
