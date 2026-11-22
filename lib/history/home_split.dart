import 'package:flutter/widgets.dart';

/// Whether home lays out the project list and a dashboard side by side.
/// Logical pixels; true for a full-width landscape iPad, false for portrait,
/// iPhone, and narrow Slide Over / split-view windows.
bool homeSplitActive(Size size) =>
    size.width >= 900 && size.width > size.height;
