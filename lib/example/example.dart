import 'package:dragable_grid_view/lib_dragable/dragable_gridview.dart';
import 'package:flutter/material.dart';

import 'gridview_item.dart';

class DragAbleGridViewDemo extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return DragAbleGridViewDemoState();
  }
}

class DragAbleGridViewDemoState extends State<DragAbleGridViewDemo> {
  List<ItemBin> itemBins = List();
  String actionTxtEdit = "Edit";
  String actionTxtComplete = "Done";
  String actionTxt;
  var editSwitchController = EditSwitchController();
  final List<String> heroes = [
    "Apple",
    "Orange",
    "Banana",
    "Donut",
    "Mango",
    "Lemon",
    "Lychee",
    "Papaya",
    "Durian",
    "Penguin",
    "Grapes",
    "Pomelo",
    "Coconut",
    "Guava",
    "Peach",
  ];

  @override
  void initState() {
    super.initState();
    actionTxt = actionTxtEdit;
    heroes.forEach((heroName) {
      itemBins.add(ItemBin(heroName));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Draggable GridView"),
        actions: <Widget>[
          Center(
              child: GestureDetector(
            child: Container(
              child: Text(
                actionTxt,
                style: TextStyle(fontSize: 19.0),
              ),
              margin: EdgeInsets.only(right: 12),
            ),
            onTap: () {
              changeActionState();
              editSwitchController.editStateChanged();
            },
          ))
        ],
      ),
      body: DragAbleGridView(
        mainAxisSpacing: 10.0,
        crossAxisSpacing: 10.0,
        childAspectRatio: 1.8,
        crossAxisCount: 4,
        itemBins: itemBins,
        editSwitchController: editSwitchController,
        /******************************new parameter*********************************/
        isOpenDragAble: true,
        animationDuration: 300, //milliseconds
        longPressDuration: 800, //milliseconds
        /******************************new parameter*********************************/
        deleteIcon: Image.asset("images/close.png", width: 15.0, height: 15.0),
        child: (int position) {
          return Container(
            padding: EdgeInsets.fromLTRB(8.0, 5.0, 8.0, 5.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(3.0)),
              border: Border.all(color: Colors.white),
              color: Colors.blue,
            ),
            // Because this layout and the delete_Icon are in the same Stack,
            // setting marginTop and marginRight will make the icon in the proper position.
            margin: EdgeInsets.only(top: 6.0, right: 6.0),
            child: Text(
              itemBins[position].data,
              style: TextStyle(
                fontSize: 16.0,
                color: Colors.white,
              ),
            ),
          );
        },
        editChangeListener: () {
          changeActionState();
        },
      ),
    );
  }

  void changeActionState() {
    if (actionTxt == actionTxtEdit) {
      setState(() {
        actionTxt = actionTxtComplete;
      });
    } else {
      setState(() {
        actionTxt = actionTxtEdit;
      });
    }
  }
}
