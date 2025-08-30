import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

const Map<Level, Color> levelColors = {
  Level.trace: Colors.grey,
  Level.debug: Colors.green,
  Level.info: Colors.blue,
  Level.warning: Colors.amber,
  Level.error: Colors.red,
  Level.fatal: Colors.purpleAccent,
};
