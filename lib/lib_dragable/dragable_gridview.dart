import 'dart:async';

import 'package:flutter/material.dart';

import 'dragable_utils.dart';

typedef CreateChild = Widget Function(int position);
typedef EditChangeListener();
typedef DeleteIconClickListener = void Function(int index);

/// Prepare to modify the outline: 3. To fit 2-3 texts
class DragAbleGridView<T extends DragAbleGridViewBin> extends StatefulWidget {
  final CreateChild child;
  final List<T> itemBins;

  /// GridView shows several children in a row
  final int crossAxisCount;

  /// In order to calculate the gap between items, crossAxisSpacing is used
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  //cross-axis to the main-axis
  final double childAspectRatio;

  /// Edit switch controller, trigger editing by clicking a button
  final EditSwitchController editSwitchController;

  /// Press and hold to trigger the editing state, you can monitor the state to change the state of the editing button (edit switch, trigger editing by button)
  final EditChangeListener editChangeListener;
  final bool isOpenDragAble;
  final int animationDuration;
  final int longPressDuration;

  /// Delete button
  final Widget deleteIcon;
  final DeleteIconClickListener deleteIconClickListener;

  DragAbleGridView({
    @required this.child,
    @required this.itemBins,
    this.crossAxisCount: 4,
    this.childAspectRatio: 1.0,
    this.mainAxisSpacing: 0.0,
    this.crossAxisSpacing: 0.0,
    this.editSwitchController,
    this.editChangeListener,
    this.isOpenDragAble: false,
    this.animationDuration: 300,
    this.longPressDuration: 800,
    this.deleteIcon,
    this.deleteIconClickListener,
  }) : assert(
          child != null,
          itemBins != null,
        );

  @override
  State<StatefulWidget> createState() {
    return DragAbleGridViewState<T>();
  }
}

class DragAbleGridViewState<T extends DragAbleGridViewBin>
    extends State<DragAbleGridView>
    with SingleTickerProviderStateMixin
    implements DragAbleViewListener {
  var physics = ScrollPhysics();
  double screenWidth;
  double screenHeight;

  /// Position record of Item position during dragging
  List<int> itemPositions;

  /// The following 4 variables specifically look at the code in the onTapDown () method, with specific comments
  double itemWidth = 0.0;
  double itemHeight = 0.0;
  double itemWidthChild = 0.0;
  double itemHeightChild = 0.0;

  /// The following two variables specifically look at the code in the onTapDown () method, with specific comments
  double blankSpaceHorizontal = 0.0;
  double blankSpaceVertical = 0.0;
  double xBlankPlace = 0.0;
  double yBlankPlace = 0.0;

  Animation<double> animation;
  AnimationController controller;
  int startPosition;
  int endPosition;
  bool isRest = false;

  /// Covering more than 1/5 will trigger the animation, as long as one of the width and height can meet
  // double areaCoverageRatio=1/5;
  Timer timer;
  bool isRemoveItem = false;
  bool isHideDeleteIcon = true;
  Future _future;
  double xyDistance = 0.0;
  double yDistance = 0.0;
  double xDistance = 0.0;

  @override
  void initState() {
    super.initState();
    widget.editSwitchController.dragAbleGridViewState = this;
    controller = AnimationController(
        duration: Duration(milliseconds: widget.animationDuration),
        vsync: this);
    animation = Tween(begin: 0.0, end: 1.0).animate(controller)
      ..addListener(() {
        T offsetBin;
        int childWidgetPosition;

        if (isRest) {
          if (startPosition > endPosition) {
            for (int i = endPosition; i < startPosition; i++) {
              childWidgetPosition = itemPositions[i];
              offsetBin = widget.itemBins[childWidgetPosition];
              // Icon moves right down
              if ((i + 1) % widget.crossAxisCount == 0) {
                offsetBin.lastTimePositionX = -(screenWidth - itemWidth) * 1 +
                    offsetBin.lastTimePositionX;
                offsetBin.lastTimePositionY =
                    (itemHeight + widget.mainAxisSpacing) * 1 +
                        offsetBin.lastTimePositionY;
              } else {
                offsetBin.lastTimePositionX =
                    (itemWidth + widget.crossAxisSpacing) * 1 +
                        offsetBin.lastTimePositionX;
              }
            }
          } else {
            for (int i = startPosition + 1; i <= endPosition; i++) {
              childWidgetPosition = itemPositions[i];
              offsetBin = widget.itemBins[childWidgetPosition];
              // Icon left up
              if (i % widget.crossAxisCount == 0) {
                offsetBin.lastTimePositionX =
                    (screenWidth - itemWidth) * 1 + offsetBin.lastTimePositionX;
                offsetBin.lastTimePositionY =
                    -(itemHeight + widget.mainAxisSpacing) * 1 +
                        offsetBin.lastTimePositionY;
              } else {
                offsetBin.lastTimePositionX =
                    -(itemWidth + widget.crossAxisSpacing) * 1 +
                        offsetBin.lastTimePositionX;
              }
            }
          }
          return;
        }
        double animationValue = animation.value;

        // This code is the same as the above code, but it cannot be commissioned, and it has been tested that the calling method will not take effect.
        // startPosition greater than endPosition indicates that the target position is above, and the icon needs to be backed up by one space
        if (startPosition > endPosition) {
          for (int i = endPosition; i < startPosition; i++) {
            childWidgetPosition = itemPositions[i];
            offsetBin = widget.itemBins[childWidgetPosition];
            // The icon moves to the lower left; if the icon is on the far right, you need to move down one layer to the far left of the next layer, (where it starts)
            if ((i + 1) % widget.crossAxisCount == 0) {
              setState(() {
                offsetBin.dragPointX =
                    -xyDistance * animationValue + offsetBin.lastTimePositionX;
                offsetBin.dragPointY =
                    yDistance * animationValue + offsetBin.lastTimePositionY;
              });
            } else {
              setState(() {
                // ↑↑↑ If the icon is not on the far right, just move to the right
                offsetBin.dragPointX =
                    xDistance * animationValue + offsetBin.lastTimePositionX;
              });
            }
          }
        }
        // When the target position is below, the icon needs to move forward one
        else {
          for (int i = startPosition + 1; i <= endPosition; i++) {
            childWidgetPosition = itemPositions[i];
            offsetBin = widget.itemBins[childWidgetPosition];
            // Move the icon to the right and up; if the icon is on the far left, you need to move up one level
            if (i % widget.crossAxisCount == 0) {
              setState(() {
                offsetBin.dragPointX =
                    xyDistance * animationValue + offsetBin.lastTimePositionX;
                offsetBin.dragPointY =
                    -yDistance * animationValue + offsetBin.lastTimePositionY;
              });
            } else {
              setState(() {
                // ↑↑↑ If the icon is not on the far left, just move left
                offsetBin.dragPointX =
                    -xDistance * animationValue + offsetBin.lastTimePositionX;
              });
            }
          }
        }
      });
    animation.addStatusListener((animationStatus) {
      if (animationStatus == AnimationStatus.completed) {
        setState(() {});
        isRest = true;
        controller.reset();
        isRest = false;

        if (isRemoveItem) {
          isRemoveItem = false;
          itemPositions.removeAt(startPosition);
          onPanEndEvent(startPosition);
        } else {
          int dragPosition = itemPositions[startPosition];
          itemPositions.removeAt(startPosition);
          itemPositions.insert(endPosition, dragPosition);
          // The finger is not raised (may continue to drag), at this time the end position is equal to the start position
          startPosition = endPosition;
        }
      } else if (animationStatus == AnimationStatus.forward) {}
    });
    _initItemPositions();
  }

  void _initItemPositions() {
    itemPositions = List();
    for (int i = 0; i < widget.itemBins.length; i++) {
      itemPositions.add(i);
    }
  }

  @override
  void didUpdateWidget(DragAbleGridView<DragAbleGridViewBin> oldWidget) {
    if (itemPositions.length != widget.itemBins.length) {
      _initItemPositions();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Size screenSize = MediaQuery.of(context).size;
    screenWidth = screenSize.width;
    screenHeight = screenSize.height;
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
        physics: physics,
        scrollDirection: Axis.vertical,
        itemCount: widget.itemBins.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.crossAxisCount,
            childAspectRatio: widget.childAspectRatio,
            crossAxisSpacing: widget.crossAxisSpacing,
            mainAxisSpacing: widget.mainAxisSpacing),
        itemBuilder: (BuildContext contexts, int index) {
          return DragAbleContentView(
            isOpenDragAble: widget.isOpenDragAble,
            screenHeight: screenHeight,
            screenWidth: screenWidth,
            isHideDeleteIcon: isHideDeleteIcon,
            controller: controller,
            longPressDuration: widget.longPressDuration,
            index: index,
            dragAbleGridViewBin: widget.itemBins[index],
            dragAbleViewListener: this,
            child: Stack(
              alignment: Alignment.topRight,
              children: <Widget>[
                widget.child(index),
                Offstage(
                  offstage: isHideDeleteIcon,
                  child: GestureDetector(
                    child: widget.deleteIcon ?? Container(height: 0, width: 0),
                    onTap: () {
                      // TODO: Method is null
                      // widget.deleteIconClickListener(index);
                      setState(() {
                        widget.itemBins[index].offstage = true;
                      });
                      startPosition = index;
                      endPosition = widget.itemBins.length - 1;
                      getWidgetsSize(widget.itemBins[index]);
                      isRemoveItem = true;
                      _future = controller.forward();
                    },
                  ),
                ),
              ],
            ),
          );
        });
  }

  /// If the sizes of the items are not the same, then the relevant size of the item must be calculated before each drag
  @override
  void getWidgetsSize(DragAbleGridViewBin pressItemBin) {
    if (itemWidth == 0) {
      // Get the width of the container without borders
      itemWidth = pressItemBin.containerKey.currentContext
          .findRenderObject()
          .paintBounds
          .size
          .width;
    }
    if (itemHeight == 0) {
      itemHeight = pressItemBin.containerKey.currentContext
          .findRenderObject()
          .paintBounds
          .size
          .height;
    }

    if (itemWidthChild == 0) {
      // Gets the width of the Container with a border, which is the width of the visible Item view
      itemWidthChild = pressItemBin.containerKeyChild.currentContext
          .findRenderObject()
          .paintBounds
          .size
          .width;
    }
    if (itemHeightChild == 0) {
      itemHeightChild = pressItemBin.containerKeyChild.currentContext
          .findRenderObject()
          .paintBounds
          .size
          .height;
    }

    if (blankSpaceHorizontal == 0) {
      // Gets the width of the white space on the left and right without borders and its child Views (Containers with borders)
      blankSpaceHorizontal = (itemWidth - itemWidthChild) / 2;
    }

    if (blankSpaceVertical == 0) {
      blankSpaceVertical = (itemHeight - itemHeightChild) / 2;
    }

    if (xBlankPlace == 0) {
      // Space between border and parent layout + space between gridView Item + space between adjacent item border and parent layout
      // Therefore, the blank part of a View and adjacent View is calculated as follows, that is, greater than this value, two Items can meet and overlap
      xBlankPlace = blankSpaceHorizontal * 2 + widget.crossAxisSpacing;
    }

    if (yBlankPlace == 0) {
      yBlankPlace = blankSpaceVertical * 2 + widget.mainAxisSpacing;
    }

    if (xyDistance == 0) {
      xyDistance = screenWidth - itemWidth;
    }

    if (yDistance == 0) {
      yDistance = itemHeight + widget.mainAxisSpacing;
    }

    if (xDistance == 0) {
      xDistance = itemWidth + widget.crossAxisSpacing;
    }
  }

  int geyXTransferItemCount(int index, double xBlankPlace, double dragPointX) {
    // Maximum boundary and minimum boundary
    //double maxBoundWidth = itemWidthChild * (1-areaCoverageRatio);
    //double minBoundWidth = itemWidthChild * areaCoverageRatio;

    // Whether to cross the blank space, if not, it means that it is in place, or covers part of its original position, has not been dragged to other Items, or has been dragged multiple times and is now dragged back; there are many cases
    if (dragPointX.abs() > xBlankPlace) {
      if (dragPointX > 0) {
        // ↑↑↑ means move to the right-hand side of your original position
        return checkXAxleRight(index, xBlankPlace, dragPointX);
      } else {
        // ↑↑↑ means move to the left-hand side of your original position
        return checkXAxleLeft(index, xBlankPlace, dragPointX);
      }
    } else {
      // ↑↑↑ Even a blank area has not been crossed. It must be in its original position and return to index.
      return 0;
    }
  }

  /// When dragged to the right of its position
  int checkXAxleRight(int index, double xBlankPlace, double dragPointX) {
    double aSection = xBlankPlace + itemWidthChild;

    double rightTransferDistance = dragPointX.abs() + itemWidthChild;
    // Calculate the remainder of the left and right borders
    double rightBorder = rightTransferDistance % aSection;
    double leftBorder = dragPointX.abs() % aSection;

    // When there is adhesion to 2 items, the calculation of the proportion is the target position
    if (rightBorder < itemWidthChild && leftBorder < itemWidthChild) {
      if (itemWidthChild - leftBorder > rightBorder) {
        // Left has a large proportion, and the target position on the left is not to be animated
        return (dragPointX.abs() / aSection).floor();
      } else {
        // more right
        return (rightTransferDistance / aSection).floor();
      }
    } else if (rightBorder > itemWidthChild && leftBorder < itemWidthChild) {
      // left glue, right border is in blank area
      return (dragPointX.abs() / aSection).floor();
    } else if (rightBorder < itemWidthChild && leftBorder > itemWidthChild) {
      // right glue, the left border is in the blank area
      return (rightTransferDistance / aSection).floor();
    } else {
      // When there is no adhesion on the left and right sides, it means that the left and right sides are in a blank area, and return to 0.
      return 0;
    }
  }

  /// In the X axis direction, when dragged to the left of its own position
  int checkXAxleLeft(int index, double xBlankPlace, double dragPointX) {
    double aSection = xBlankPlace + itemWidthChild;

    double leftTransferDistance = dragPointX.abs() + itemWidthChild;

    // Calculate the remainder of the left and right borders
    double leftBorder = leftTransferDistance % aSection;
    double rightBorder = dragPointX.abs() % aSection;

    // When there is adhesion to 2 items, the calculation of the proportion is the target position
    if (rightBorder < itemWidthChild && leftBorder < itemWidthChild) {
      if (itemWidthChild - rightBorder > leftBorder) {
        // Right accounted for more, then the right is the target position to be animated
        return -(dragPointX.abs() / aSection).floor();
      } else {
        // more left
        return -(leftTransferDistance / aSection).floor();
      }
    } else if (rightBorder > itemWidthChild && leftBorder < itemWidthChild) {
      // left glue, right border is in blank area
      return -(leftTransferDistance / aSection).floor();
    } else if (rightBorder < itemWidthChild && leftBorder > itemWidthChild) {
      // right glue, the left border is in the blank area
      return -(dragPointX.abs() / aSection).floor();
    } else {
      // When there is no adhesion on the left and right sides, it means that the left and right sides are in a blank area, and return to 0.
      return 0;
    }
  }

  /// Calculate the Y-axis direction needs to move several Items
  /// 1. The target drag distance is not satisfied, 2. Drag to other items, 3. There is no adhesion with any item, 5. There is overlap with multiple items, etc. 4 cases
  /// One more thing to consider is that although the Y axis does not meet 1 / 5--4 / 5 coverage, the X axis does
  int geyYTransferItemCount(int index, double yBlankPlace, double dragPointY) {
    // Maximum boundary and minimum boundary
    // double maxBoundHeight = itemHeightChild * (1-areaCoverageRatio);
    // double minBoundHeight = itemHeightChild * areaCoverageRatio;

    // Whether the upper and lower borders meet the requirements of covering 1 / 5--4 / 5 height
    //bool isTopBoundLegitimate = topBorder > minBoundHeight && topBorder < maxBoundHeight;
    //bool isBottomBoundLegitimate = bottomBorder > minBoundHeight && bottomBorder < maxBoundHeight;

    // Whether to cross the blank space, if not, it means that it is in place, or covers part of its original position,
    // has not been dragged to other Items, or has been dragged multiple times and is now dragged back; there are many cases
    if (dragPointY.abs() > yBlankPlace) {
      // ↑↑↑ There are many cases of crossing ↓↓↓
      if (dragPointY > 0) {
        // ↑↑↑ indicates that the dragged item is now under the original position
        return checkYAxleBelow(index, yBlankPlace, dragPointY);
      } else {
        // ↑↑↑ indicates that the item being dragged is now above the original position
        return checkYAxleAbove(index, yBlankPlace, dragPointY);
      }
    } else {
      // ↑↑↑ Not crossed Back to index
      return index;
    }
  }

  /// When dragged to the original position on the Y axis, the calculation drags several lines
  int checkYAxleAbove(int index, double yBlankPlace, double dragPointY) {
    double aSection = yBlankPlace + itemHeightChild;

    double topTransferDistance = dragPointY.abs() + itemHeightChild;

    // Find the remainder of the bottom border. The remainder is less than itemHeightChild, which means to cover the item below. The remainder is greater than itemHeightChild, which means that the bottom border is in a blank area.
    double topBorder = (topTransferDistance) % aSection;
    // Find the remainder of the upper border. The remainder is less than itemHeightChild, which means to cover with the item above. The remainder is greater than itemHeightChild, which means that the upper border is in a blank area.
    double bottomBorder = dragPointY.abs() % aSection;

    if (topBorder < itemHeightChild && bottomBorder < itemHeightChild) {
      // ↑↑↑ Cover with 2 and item at the same time (both upper and lower borders are in the coverage area)
      if (itemHeightChild - bottomBorder > topBorder) {
        // ↑↑↑ 2 sticky to calculate which proportion is more, the smaller the topBorder, the larger the coverage area, the larger the bottomBorder, the larger the coverage area;
        // Bottom border ratio is larger
        return index -
            (dragPointY.abs() / aSection).floor() * widget.crossAxisCount;
      } else {
        // ↑↑↑ The proportion of the upper border is large
        return index -
            (topTransferDistance / aSection).floor() * widget.crossAxisCount;
      }
    } else if (topBorder > itemHeightChild && bottomBorder < itemHeightChild) {
      // ↑↑↑ The lower border is in the coverage area, and the upper border is in the blank area.
      return index -
          (dragPointY.abs() / aSection).floor() * widget.crossAxisCount;
    } else if (topBorder < itemHeightChild && bottomBorder > itemHeightChild) {
      // ↑↑↑ The top border is in the coverage area, and the bottom border is in the blank area
      return index -
          (topTransferDistance / aSection).floor() * widget.crossAxisCount;
    } else {
      // ↑↑↑ The top border is in the coverage area, and the bottom border is in the blank area
      return index;
    }
  }

  /// One more thing to consider is that although the Y-axis does not meet the 1 / 5--4 / 5 coverage,
  /// but the X-axis does, so when returning, both the target index and the Y coverage conditions are met
  int checkYAxleBelow(int index, double yBlankPlace, double dragPointY) {
    double aSection = yBlankPlace + itemHeightChild;

    double bottomTransferDistance = dragPointY.abs() + itemHeightChild;

    // Find the remainder of the bottom border. The remainder is less than itemHeightChild, which means to cover the item below.
    // The remainder is greater than itemHeightChild, which means that the bottom border is in a blank area.
    double bottomBorder = bottomTransferDistance % aSection;
    // Find the remainder of the upper border. The remainder is less than itemHeightChild, which means to cover with the item above.
    // The remainder is greater than itemHeightChild, which means that the upper border is in a blank area.
    double topBorder = dragPointY.abs() % aSection;

    if (bottomBorder < itemHeightChild && topBorder < itemHeightChild) {
      // ↑↑↑ Cover with 2 and item at the same time (both upper and lower borders are in the coverage area)
      if (itemHeightChild - topBorder > bottomBorder) {
        // ↑↑↑ 2 sticky to calculate which proportion is more, the smaller the topBorder, the larger the coverage area, the larger the bottomBorder, the larger the coverage area;
        // ↑↑↑ The proportion above is large
        return index +
            (dragPointY.abs() / aSection).floor() * widget.crossAxisCount;
      } else {
        // ↑↑↑ The proportion below is large
        return index +
            (bottomTransferDistance / aSection).floor() * widget.crossAxisCount;
      }
    } else if (topBorder > itemHeightChild && bottomBorder < itemHeightChild) {
      // ↑↑↑ The bottom border is in the coverage area, and the top border is in the blank area.
      return index +
          (bottomTransferDistance / aSection).floor() * widget.crossAxisCount;
    } else if (topBorder < itemHeightChild && bottomBorder > itemHeightChild) {
      //topBorder<itemHeightChild
      // ↑↑↑ The top border is in the coverage area, and the bottom border is in the blank area
      return index +
          (dragPointY.abs() / aSection).floor() * widget.crossAxisCount;
    } else {
      // ↑↑↑ and which item are not covered, the upper and lower borders are in the blank area. Just return Index
      return index;
    }
  }

  /// When you stop swiping, handle if you need animation, etc.
  @override
  void onFingerPause(int index, double dragPointX, double dragPointY,
      DragUpdateDetails updateDetail) async {
    int y = geyYTransferItemCount(index, yBlankPlace, dragPointY);
    int x = geyXTransferItemCount(index, xBlankPlace, dragPointX);

    // 2. Cannot animate while the animation is in progress.
    // 3. When the calculation is wrong, the end coordinate is less than or greater than itemBins.length.
    if (endPosition != x + y &&
        !controller.isAnimating &&
        x + y < widget.itemBins.length &&
        x + y >= 0 &&
        widget.itemBins[index].dragAble) {
      endPosition = x + y;
      _future = controller.forward();
    }
  }

  /// After dragging, reorder itemBins according to the sorting in itemPositions
  /// and re-initialize itemPositions
  @override
  void onPanEndEvent(index) async {
    widget.itemBins[index].dragAble = false;
    if (controller.isAnimating) {
      await _future;
    }
    setState(() {
      List<T> itemBi = List();
      T bin;
      for (int i = 0; i < itemPositions.length; i++) {
        bin = widget.itemBins[itemPositions[i]];
        bin.dragPointX = 0.0;
        bin.dragPointY = 0.0;
        bin.lastTimePositionX = 0.0;
        bin.lastTimePositionY = 0.0;
        itemBi.add(bin);
      }
      widget.itemBins.clear();
      widget.itemBins.addAll(itemBi);
      _initItemPositions();
    });
  }

  /// External use EditSwitchController to control editing status
  /// When calling this method, change the state of the delete icon on the GridView Item to change the state
  void changeDeleteIconState() {
    setState(() {
      isHideDeleteIcon = !isHideDeleteIcon;
    });
  }

  @override
  void onTapDown(int index) {
    endPosition = index;
  }

  @override
  double getItemHeight() {
    return itemHeight;
  }

  @override
  double getItemWidth() {
    return itemWidth;
  }

  @override
  void onPressSuccess(int index) {
    setState(() {
      startPosition = index;
      if (widget.editChangeListener != null && isHideDeleteIcon == true) {
        widget.editChangeListener();
      }
      isHideDeleteIcon = false;
    });
  }
}

class EditSwitchController {
  DragAbleGridViewState dragAbleGridViewState;

  void editStateChanged() {
    dragAbleGridViewState.changeDeleteIconState();
  }
}

class DragAbleContentView<T extends DragAbleGridViewBin>
    extends StatefulWidget {
  final Widget child;
  final bool isOpenDragAble;
  final double screenWidth, screenHeight;
  final bool isHideDeleteIcon;
  final AnimationController controller;
  final int longPressDuration;
  final int index;
  final T dragAbleGridViewBin;
  final DragAbleViewListener dragAbleViewListener;

  DragAbleContentView({
    @required this.child,
    @required this.isOpenDragAble,
    @required this.screenHeight,
    @required this.screenWidth,
    @required this.isHideDeleteIcon,
    @required this.controller,
    @required this.longPressDuration,
    @required this.index,
    @required this.dragAbleGridViewBin,
    @required this.dragAbleViewListener,
  });

  @override
  State<StatefulWidget> createState() {
    return DragAbleContentViewState<T>();
  }
}

class DragAbleContentViewState<T extends DragAbleGridViewBin>
    extends State<DragAbleContentView<T>> {
  Timer timer;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isOpenDragAble
          ? (detail) {
              handleOnTapDownEvent(detail);
            }
          : null,
      onPanUpdate: widget.isOpenDragAble
          ? (updateDetail) {
              handleOnPanUpdateEvent(updateDetail);
            }
          : null,
      onPanEnd: widget.isOpenDragAble
          ? (upDetail) {
              handleOnPanEndEvent(widget.index);
            }
          : null,
      onTapUp: widget.isOpenDragAble
          ? (tapUpDetails) {
              handleOnTapUp();
            }
          : null,
      child: Offstage(
        offstage: widget.dragAbleGridViewBin.offstage,
        child: Container(
          alignment: Alignment.center,
          //color: Colors.grey,
          key: widget.dragAbleGridViewBin.containerKey,
          child: OverflowBox(
              maxWidth: widget.screenWidth,
              maxHeight: widget.screenHeight,
              alignment: Alignment.center,
              child: Center(
                child: Container(
                  key: widget.dragAbleGridViewBin.containerKeyChild,
                  transform: Matrix4.translationValues(
                      widget.dragAbleGridViewBin.dragPointX,
                      widget.dragAbleGridViewBin.dragPointY,
                      0.0),
                  child: widget.child,
                ),
              )),
        ),
      ),
    );
  }

  void handleOnPanEndEvent(int index) {
    T pressItemBin = widget.dragAbleGridViewBin;
    pressItemBin.isLongPress = false;
    if (!pressItemBin.dragAble) {
      pressItemBin.dragPointY = 0.0;
      pressItemBin.dragPointX = 0.0;
    } else {
      widget.dragAbleGridViewBin.dragAble = false;
      widget.dragAbleViewListener.onPanEndEvent(index);
    }
  }

  void handleOnTapUp() {
    T pressItemBin = widget.dragAbleGridViewBin;
    pressItemBin.isLongPress = false;
    if (!widget.isHideDeleteIcon) {
      setState(() {
        pressItemBin.dragPointY = 0.0;
        pressItemBin.dragPointX = 0.0;
      });
    }
  }

  void handleOnPanUpdateEvent(DragUpdateDetails updateDetail) {
    T pressItemBin = widget.dragAbleGridViewBin;
    pressItemBin.isLongPress = false;
    if (pressItemBin.dragAble) {
      double deltaDy = updateDetail.delta.dy;
      double deltaDx = updateDetail.delta.dx;

      double dragPointY = pressItemBin.dragPointY += deltaDy;
      double dragPointX = pressItemBin.dragPointX += deltaDx;

      if (widget.controller.isAnimating) {
        return;
      }
      bool isMove = deltaDy.abs() > 0.0 || deltaDx.abs() > 0.0;

      if (isMove) {
        if (timer != null && timer.isActive) {
          timer.cancel();
        }
        setState(() {});
        timer = Timer(Duration(milliseconds: 100), () {
          widget.dragAbleViewListener.onFingerPause(
              widget.index, dragPointX, dragPointY, updateDetail);
        });
      }
    }
  }

  void handleOnTapDownEvent(TapDownDetails detail) {
    T pressItemBin = widget.dragAbleGridViewBin;
    widget.dragAbleViewListener.getWidgetsSize(pressItemBin);

    if (!widget.isHideDeleteIcon) {
      // Get the y coordinate of the control on the screen
      double ss = pressItemBin.containerKey.currentContext
          .findRenderObject()
          .getTransformTo(null)
          .getTranslation()
          .y;
      double aa = pressItemBin.containerKey.currentContext
          .findRenderObject()
          .getTransformTo(null)
          .getTranslation()
          .x;

      // Calculate how many pixels the control should be offset after the finger points down
      double itemHeight = widget.dragAbleViewListener.getItemHeight();
      double itemWidth = widget.dragAbleViewListener.getItemWidth();
      pressItemBin.dragPointY = detail.globalPosition.dy - ss - itemHeight / 2;
      pressItemBin.dragPointX = detail.globalPosition.dx - aa - itemWidth / 2;
    }

    // mark the start of the long press event
    pressItemBin.isLongPress = true;
    // Set the draggable flag to false; (dragAble is true, the control can be dragged, temporarily set to false, etc.
    // until the long press time is considered as dragging)
    pressItemBin.dragAble = false;
    widget.dragAbleViewListener.onTapDown(widget.index);
    _handLongPress();
  }

  /// Custom long press event, only 800ms long can trigger drag
  void _handLongPress() async {
    await Future.delayed(Duration(milliseconds: widget.longPressDuration));
    if (widget.dragAbleGridViewBin.isLongPress) {
      setState(() {
        widget.dragAbleGridViewBin.dragAble = true;
      }); // Adsorption effect SetState cannot be deleted
      widget.dragAbleViewListener.onPressSuccess(widget.index);
    }
  }
}

abstract class DragAbleViewListener<T extends DragAbleGridViewBin> {
  void getWidgetsSize(T pressItemBin);
  void onTapDown(int index);
  void onFingerPause(int index, double dragPointX, double dragPointY,
      DragUpdateDetails updateDetail);
  void onPanEndEvent(int index);
  double getItemHeight();
  double getItemWidth();
  void onPressSuccess(int index);
}
