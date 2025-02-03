import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

class Titlebar extends StatelessWidget {
  const Titlebar({super.key});

  @override
  Widget build(BuildContext context) {
    return WindowTitleBarBox(
      child: Row(
        children: [
          Expanded(
            child: MoveWindow(
              child: Container(
                height: 50,
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: Text("Byte Music"),
              ),
            )
          ),
          Row(
            children: [
              CloseWindowButton(
                colors: WindowButtonColors(
                  iconNormal: Colors.white
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
