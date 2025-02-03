import 'dart:ffi' as ffi;
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:byte_player/screens/player_panel.dart';
import 'package:byte_player/screens/signin_screen.dart';
import 'package:byte_player/services/api_service.dart';
import 'package:byte_player/utils/nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:win32/win32.dart';

final ffi.DynamicLibrary gdi32 = ffi.DynamicLibrary.open('gdi32.dll');

final int Function(
    int nLeftRect,
    int nTopRect,
    int nRightRect,
    int nBottomRect,
    int nWidthEllipse,
    int nHeightEllipse,
    ) createRoundRectRgnPtr = gdi32.lookupFunction<
    ffi.IntPtr Function(
        ffi.Int32, ffi.Int32, ffi.Int32, ffi.Int32, ffi.Int32, ffi.Int32
        ),
    int Function(
        int, int, int, int, int, int
        )
>('CreateRoundRectRgn');


void applyRoundedCorners(int radius, double width, double height) {

  // Get the native window handle from bitsdojo_window.
  final hwnd = appWindow.handle;

  // Create a rounded rectangle region with the specified radius.
  final region = createRoundRectRgnPtr(
    0, 0,
    width.toInt() + 100,
    height.toInt() + 100,
    radius,
    radius,
  );
  // Apply the region to the window.
  SetWindowRgn(hwnd!, region, FALSE);

  // It's safe to delete the region handle after setting it,
  // as the system owns the region from now on.
  DeleteObject(region);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  MediaKit.ensureInitialized();
  doWhenWindowReady(() {
    appWindow.alignment = Alignment.centerRight ;
    appWindow.title = "Byte Player";
    appWindow.size = Size(400, 800);
    appWindow.minSize = Size(400, 750);
    appWindow.maxSize = Size(400, 800);
    appWindow.show();
  });
  applyRoundedCorners(20, 400, 900);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerProvider())
      ],
      child:const MyApp()
    )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Byte Music',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: ApiService.youTubeApi == null ? SignInPage():Nav() ,
    );
  }
}

