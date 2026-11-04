import 'package:flutter/material.dart';

class PlacesHorizontalList extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Map<String, dynamic>> items;
  final IconData icon;
  final Color accentColor;
  final Color surfaceColor;
  final Color textColor;
  final bool isLoading;
  final Function(Map<String, dynamic>) onItemTap;

  const PlacesHorizontalList({
    super.key,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.icon,
    required this.accentColor,
    required this.surfaceColor,
    required this.textColor,
    required this.isLoading,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && !isLoading) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w800)),
            const Spacer(),
            Text(subtitle, style: TextStyle(color: accentColor, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ],
        ),
        const SizedBox(height: 12),
        if (isLoading && items.isEmpty)
          SizedBox(height: 110, child: Center(child: CircularProgressIndicator(color: accentColor))),
        if (items.isNotEmpty)
          SizedBox(
              height: 110,
              child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return GestureDetector(
                      onTap: () => onItemTap(item),
                      child: Container(
                        width: 160,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.grey.withOpacity(0.1))),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: accentColor.withOpacity(.1), shape: BoxShape.circle), child: Icon(icon, color: accentColor, size: 16)),
                              const Spacer(),
                              Text(item['name']!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Row(
                                  children: [
                                    const Icon(Icons.route_rounded, color: Colors.grey, size: 10),
                                    const SizedBox(width: 4),
                                    Text(item['distance']!, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w600)),
                                    const Spacer(),
                                    Expanded(child: Text(item['type']!, style: TextStyle(color: accentColor, fontSize: 9, fontWeight: FontWeight.w700), textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis))
                                  ]
                              )
                            ]
                        ),
                      ),
                    );
                  }
              )
          )
      ],
    );
  }
}