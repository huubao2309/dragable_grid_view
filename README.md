# Dragable Grid View

## Dragable Grid View:

![Dragable_Grid_View](https://github.com/huubao2309/dragable_grid_view/blob/master/images/dragger_grid.gif)


### Use Dragable Grid View:

```dart
      body: DragAbleGridView(
        mainAxisSpacing: 10.0,
        crossAxisSpacing: 10.0,
        childAspectRatio: 1.8,
        crossAxisCount: 4,
        itemBins: itemBins, // Items Source
        editSwitchController: editSwitchController, // Controler for Edit
        /******************************new parameter*********************************/
        isOpenDragAble: true,
        animationDuration: 300, //milliseconds
        longPressDuration: 800, //milliseconds
        /******************************new parameter*********************************/
        deleteIcon: Image.asset("images/close.png", width: 15.0, height: 15.0), // icon delete
        child: (int position) {
          return Container(
            padding: EdgeInsets.fromLTRB(8.0, 5.0, 8.0, 5.0),
            decoration: BoxDecoration(
              // ...
            ),
            // Because this layout and the delete_Icon are in the same Stack,
            // setting marginTop and marginRight will make the icon in the proper position.
            margin: EdgeInsets.only(top: 6.0, right: 6.0),
            child: //... content
            ,
          );
        },
        editChangeListener: () {
          changeActionState(); // Set action "Done" or "Edit"
        },
      ),
```
