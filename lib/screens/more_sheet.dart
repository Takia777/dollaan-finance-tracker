import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../ui/widgets.dart';
import 'achievements_screen.dart';
import 'chat_screen.dart';

/// Sheet "More features" dari Home. Saving mode → tab Goals.
void showMoreSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.putih,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) {
      void soon() {
        Navigator.pop(ctx);
        showSnack(context, 'Coming soon in the next version ✨');
      }

      final items = <(IconData, String, Color, VoidCallback)>[
        (Icons.history_rounded, 'History', AppColors.unguTua, () {
          Navigator.pop(ctx);
          app.tab.value = 2;
        }),
        (Icons.account_balance_wallet_rounded, 'Budget', AppColors.ungu, soon),
        (Icons.category_rounded, 'Categories', AppColors.tosca, soon),
        (Icons.bar_chart_rounded, 'Reports', AppColors.kuning, () {
          Navigator.pop(ctx);
          app.tab.value = 2;
        }),
        (Icons.event_repeat_rounded, 'Recurring', AppColors.tosca, soon),
        (Icons.chat_rounded, 'Chatbot', AppColors.kuning, () {
          Navigator.pop(ctx);
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ChatScreen()));
        }),
        (Icons.emoji_events_rounded, 'Rewards', AppColors.ungu, () {
          Navigator.pop(ctx);
          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AchievementsScreen()));
        }),
        (Icons.help_rounded, 'Help', AppColors.unguTua, soon),
      ];

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(color: AppColors.muted.o(0.35), borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Text('More features', style: ts(18, FontWeight.w800))),
                  CircleBtn(icon: Icons.close_rounded, size: 36, bg: AppColors.sakura, onTap: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  app.tab.value = 1;
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.tosca, borderRadius: BorderRadius.circular(22)),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(color: AppColors.kuning, shape: BoxShape.circle),
                        child: const Icon(Icons.savings_rounded, color: AppColors.unguTua),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Saving mode', style: ts(16, FontWeight.w700, AppColors.putih)),
                            Text('Goals, streaks & achievements',
                                style: ts(12, FontWeight.w500, AppColors.putih.o(0.75))),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.putih),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
                children: [
                  for (final it in items)
                    GestureDetector(
                      onTap: it.$4,
                      child: Column(
                        children: [
                          IconBubble(icon: it.$1, color: it.$3, size: 56),
                          const SizedBox(height: 8),
                          Text(it.$2, style: ts(12, FontWeight.w600)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
