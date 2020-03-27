import 'package:dragable_grid_view/lib_dragable/dragable_utils.dart';

class ItemBin extends DragAbleGridViewBin {
  ItemBin(this.data);

  String data;

  @override
  String toString() {
    return 'Item Dragable: {data: $data, dragPointX: $dragPointX, dragPointY: $dragPointY, ' +
        'lastTimePositionX: $lastTimePositionX, lastTimePositionY: $lastTimePositionY, ' +
        'containerKey: $containerKey, containerKeyChild: $containerKeyChild, isLongPress: $isLongPress, dragAble: $dragAble}';
  }
}
