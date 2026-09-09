import 'package:flutter/material.dart';

/// App-lifetime-scoped ScaffoldMessenger, attached to MaterialApp.router in
/// app.dart. Use this instead of ScaffoldMessenger.of(context) for any
/// SnackBar that must survive the calling screen's own rebuild cycle — a
/// screen that rebuilds while a duration-based SnackBar is showing (e.g.
/// campaign_detail_screen.dart's providers refetch on realtime ticks) can
/// permanently break that SnackBar's dismiss timer if it's tied to
/// ScaffoldMessenger.of(context) instead of this stable key.
final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
