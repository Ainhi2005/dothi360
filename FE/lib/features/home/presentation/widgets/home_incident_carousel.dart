import 'package:flutter/material.dart';
import '../../../../core/theme/app_dimens.dart';
import 'home_incident_card.dart';

class HomeIncidentCarousel extends StatelessWidget {
  const HomeIncidentCarousel({super.key, required this.items});
  final List<Map<String, dynamic>> items;
  @override
  Widget build(BuildContext context) => items.isEmpty
      ? const SizedBox.shrink()
      : SizedBox(
          height: AppDimens.homeCarouselHeight,
          child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              itemBuilder: (context, index) =>
                  HomeIncidentCard(incident: items[index]),
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppDimens.spacingSm)));
}
