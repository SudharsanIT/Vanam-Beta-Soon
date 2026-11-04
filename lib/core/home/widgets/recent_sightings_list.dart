import 'package:flutter/material.dart';

class RecentSightingsList extends StatelessWidget {
  final List<Map<String, dynamic>> sightings;
  final Color surfaceColor;
  final Color textColor;
  final Color subTextColor;
  final Color accentColor;
  final Function(Map<String, dynamic>, int) onItemTap;

  const RecentSightingsList({
    super.key,
    required this.sightings,
    required this.surfaceColor,
    required this.textColor,
    required this.subTextColor,
    required this.accentColor,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (sightings.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
            children: [
              Text('RECENT WILDLIFE', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('LIVE DATA', style: TextStyle(color: accentColor, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1))
            ]
        ),
        const SizedBox(height: 12),
        SizedBox(
            height: 188,
            child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: sightings.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, index) {
                  final item = sightings[index];
                  return GestureDetector(
                    onTap: () => onItemTap(item, index),
                    child: Container(
                      width: 165,
                      decoration: BoxDecoration(color: surfaceColor, borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.grey.withOpacity(0.1))),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                                children: [
                                  Hero(
                                      tag: 'sighting_$index',
                                      child: Image.network(item['image']?.toString() ?? '', height: 100, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 100, color: Colors.grey.withOpacity(0.1), child: const Center(child: Icon(Icons.pets_rounded, color: Colors.grey))))
                                  ),
                                  Positioned(
                                      left: 9, top: 9,
                                      child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: Colors.black.withOpacity(.65), borderRadius: BorderRadius.circular(10)), child: Text(item['risk']?.toString() ?? 'OBSERVED', style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w900)))
                                  )
                                ]
                            ),
                            Padding(
                                padding: const EdgeInsets.all(11),
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item['title']?.toString() ?? 'Wildlife', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 5),
                                      Text('${item['distance'] ?? '--'} • ${item['time'] ?? '--'}', style: TextStyle(color: subTextColor, fontSize: 9))
                                    ]
                                )
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