import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meiarife/screens/app_screen/myapp.dart';
import 'package:meiarife/screens/ui_screens/homescreen.dart';
import 'package:meiarife/screens/app_screen/department_list_screen.dart';
import 'package:meiarife/screens/app_screen/meiari_home.dart';
import 'package:meiarife/screens/app_screen/login_page.dart';
import 'package:meiarife/screens/geo_locator/get_location_cubit.dart';
// import 'package:meiarife/screens/app_screen/document_editor.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  // Fetch the available cameras before initializing the app.
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error in fetching the cameras: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => GetLocationCubit(),
        ), // Provide GetLocationCubit
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/home': (context) => HomeScreen(),
          '/department': (context) => DepartmentListScreen(),
          '/': (context) => const MeiAriHomeScreen(),
          '/login': (context) => const LoginPage(),
          '/signature': (context) => const AppSignature(),
          // '/': (context) => DevEditor(),
        },
      ),
    );
  }
}
