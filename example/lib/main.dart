import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int dropDownValue;

  @override
  void initState() {
    dropDownValue = 5;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        drawer: Drawer(),
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: ListView(children: [
          ...List.generate(
              500,
              (x) => InkWell(
                  onTap: () => print("Tapped $x"),
                  child: Container(
                      padding: EdgeInsets.all(
                        10.0,
                      ),
                      child: Text('List element ' + x.toString())))),
          SizedBox(
            height: 100,
          ),
          TextFormField(key: Key('TextField')),
          DropdownButton<int>(
            key: Key('Dropdown'),
            value: dropDownValue,
            onChanged: (value) {
              setState(() {
                dropDownValue = value;
              });
            },
            items: List.generate(
                100,
                (x) => DropdownMenuItem<int>(
                      key: Key("item_$x"),
                      value: x,
                      child: Text('Select element ' + x.toString()),
                    )),
          )
        ]),
      ),
    );
  }
}
