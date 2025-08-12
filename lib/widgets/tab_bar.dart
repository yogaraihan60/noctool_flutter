import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../state/tabs.dart';

class TabsBar extends StatelessWidget {
  final TabsController controller;
  const TabsBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final tabs = controller.tabs;
    final activeId = controller.activeId;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: tabs.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final t = tabs[index];
            final isActive = t.id == activeId;
            return InkWell(
              onTap: () {
                controller.setActive(t.id);
                context.go(t.route);
              }, onDoubleTap: () {
                // Prevent duplicate tabs by reusing existing
                controller.setActive(t.id);
                context.go(t.route);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.title,
                      style: TextStyle(
                        fontSize: 13,
                        color: isActive
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        controller.closeTab(t.id);
                        context.go(controller.active?.route ?? '/dashboard');
                      },
                      child: const Icon(Icons.close, size: 14),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

