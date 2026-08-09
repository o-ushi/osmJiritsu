import 'package:flutter/material.dart';

/// App bar without the default back chevron — screens rely on the system
/// edge-swipe gesture (and wizard [PopScope] where applicable) instead.
class OsmAppBar extends AppBar {
  OsmAppBar({
    super.key,
    super.title,
    super.actions,
    super.centerTitle,
    super.backgroundColor,
    super.foregroundColor,
    super.elevation,
    super.toolbarHeight,
  }) : super(automaticallyImplyLeading: false);
}
