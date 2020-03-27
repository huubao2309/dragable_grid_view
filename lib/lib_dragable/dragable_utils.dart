import 'package:flutter/material.dart';

class DragAbleGridViewBin {
  double dragPointX = 0.0;
  double dragPointY = 0.0;
  double lastTimePositionX = 0.0;
  double lastTimePositionY = 0.0;
  GlobalKey containerKey = GlobalKey();
  GlobalKey containerKeyChild = GlobalKey();
  bool isLongPress = false;
  bool dragAble = false;

  /// Whether to hide, not hidden by default
  bool offstage = false;
}
