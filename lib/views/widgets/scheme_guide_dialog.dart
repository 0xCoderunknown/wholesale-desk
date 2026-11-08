import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// Interactive Wholesale Scheme Guide & Template Selector Dialog.
/// Deconstructs wholesale scheme syntax and provides 1-tap template insertion.
class SchemeGuideDialog extends StatelessWidget {
  final ValueChanged<String>? onSelectTemplate;

  const SchemeGuideDialog({super.key, this.onSelectTemplate});

  static Future<String?> show(
    BuildContext context, {
    ValueChanged<String>? onSelectTemplate,
  }) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => SchemeGuideDialog(
        onSelectTemplate: (val) {
          onSelectTemplate?.call(val);
          Navigator.of(ctx).pop(val);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      title: const Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: AppTheme.schemeAmber, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Wholesale Scheme Guide',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.slate800),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Wholesale Desk supports automated cart math for standard trade formats, plus informational notes:',
                style: TextStyle(fontSize: 12, color: AppTheme.slate600, height: 1.4),
              ),
              const SizedBox(height: 14),

              // 1. Free Goods
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEFCE8),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFDE047)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('🎁 ', style: TextStyle(fontSize: 14)),
                        Text(
                          'Free Goods Scheme (X+Y)',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF92400E)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Buy X units, get Y free. The cart automatically calculates and adds free items upon clicking [APPLY].',
                      style: TextStyle(fontSize: 11, color: Color(0xFF78350F), height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildTemplateChip(context, '10+1'),
                        _buildTemplateChip(context, '12+1 Free'),
                        _buildTemplateChip(context, '20+1'),
                        _buildTemplateChip(context, '24+2'),
                        _buildTemplateChip(context, '50+5'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 2. Percentage Discount
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text('🏷️ ', style: TextStyle(fontSize: 14)),
                        Text(
                          'Percentage Discount (N%)',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF065F46)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Deducts N% from unit rate upon clicking [APPLY]. To enforce a minimum quantity for this discount, set the product\'s MOQ below.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF047857), height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildTemplateChip(context, '2% CD'),
                        _buildTemplateChip(context, '3% CD'),
                        _buildTemplateChip(context, '5% Scheme'),
                        _buildTemplateChip(context, '10% Off'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3. Informational Note
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.slate100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.slate300),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('📢 ', style: TextStyle(fontSize: 14)),
                        Text(
                          'Informational Note',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.slate700),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Any text without "+" or "%" (e.g. "Diwali Gift Inside"). Displays as an announcement badge with zero cart price manipulation.',
                      style: TextStyle(fontSize: 11, color: AppTheme.slate600, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildTemplateChip(BuildContext context, String template) {
    return InkWell(
      onTap: () {
        if (onSelectTemplate != null) {
          onSelectTemplate!(template);
        } else {
          Navigator.of(context).pop(template);
        }
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppTheme.slate300, width: 0.8),
        ),
        child: Text(
          template,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.slate800),
        ),
      ),
    );
  }
}

