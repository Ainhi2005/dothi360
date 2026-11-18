import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class AppMapTileStyle {
  AppMapTileStyle._();

  static Widget lightMuted(
    BuildContext context,
    Widget tileWidget,
    TileImage tile,
  ) {
    // Return tileWidget directly without heavy shader matrix for 60fps map panning
    return tileWidget;
  }
}
