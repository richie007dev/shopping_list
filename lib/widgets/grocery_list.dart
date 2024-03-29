import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _errorMessage;
  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https('shopping-list-831b0-default-rtdb.firebaseio.com',
        'shopping-list.json');
    try {
      final response = await http.get(url);
      print(response.statusCode);

      final List<GroceryItem> loadedItems = [];
      if (response.statusCode >= 400) {
        setState(() {
          _errorMessage = 'Failed to fetch data! please try again.';
        });
        return;
      }
      if (response.body == 'null') {
        setState(
          () {
            _isLoading = false;
          },
        );
        return;
      }
      final Map<String, dynamic> listData = json.decode(response.body);
      for (final item in listData.entries) {
        final category = categories.entries
            .firstWhere((categoryItem) =>
                categoryItem.value.title == item.value['category'])
            .value;

        loadedItems.add(GroceryItem(
            id: item.key,
            name: item.value['name'],
            quantity: item.value['quantity'],
            category: category));
      }
      setState(
        () {
          _groceryItems = loadedItems;
          _isLoading = false;
        },
      );
    } catch (error) {
      setState(() {
        _errorMessage = 'Something went wrong! please try again.';
      });
    }
  }

  void _addItem() async {
    final item = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (cxt) => const NewItem(),
      ),
    );
    if (item == null) {
      return;
    }
    setState(() {
      _groceryItems.add(item);
    });
  }

  void _deleteItem(GroceryItem item) async {
    var _text = 'Item Deleted';
    final itemIndex = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.removeAt(itemIndex);
    });
    final url = Uri.https('shopping-list-831b0-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      setState(() {
        _text = 'Item not deleted';
        _groceryItems.insert(itemIndex, item);
      });
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(_text),
        duration: const Duration(seconds: 3),
        // action: SnackBarAction(
        //   label: 'Undo',
        //   onPressed: () {
        //     setState(
        //       () {
        //         _groceryItems.insert(itemIndex, item);
        //       },
        //     );
        //   },
        // ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Uh oh... nothing here!",
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color: Theme.of(context).colorScheme.onBackground,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            "Try adding new item!",
            style: Theme.of(context)
                .textTheme
                .bodyLarge!
                .copyWith(color: Theme.of(context).colorScheme.onBackground),
          )
        ],
      ),
    );
    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }
    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          background: Container(
            color: Theme.of(context).colorScheme.error.withOpacity(0.75),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          key: ValueKey(_groceryItems[index]),
          onDismissed: (direction) {
            print(direction);
            _deleteItem(_groceryItems[index]);
          },
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              height: 24,
              width: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(_groceryItems[index].quantity.toString()),
          ),
        ),
      );
    }
    if (_errorMessage != null) {
      content = Center(
        child: Text(_errorMessage!),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [IconButton(onPressed: _addItem, icon: const Icon(Icons.add))],
      ),
      body: content,
    );
  }
}
