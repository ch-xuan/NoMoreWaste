import 'package:flutter/material.dart';
import 'features/splash/splash_screen.dart';

class NoMoreWasteApp extends StatelessWidget {
  const NoMoreWasteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NoMoreWaste',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B7F5A), // Leaf Green
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7FAF9),
      ),
      home: const SplashScreen(),
    );
  }
}




// import 'package:flutter/material.dart';
// import 'core/routing/app_routes.dart';
// import 'features/auth/post_login_router.dart';

// class NoMoreWasteApp extends StatelessWidget {
//   const NoMoreWasteApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'NoMoreWaste',
//       theme: ThemeData(
//         useMaterial3: true,
//         scaffoldBackgroundColor: const Color(0xFFF7F3EA), // warm cream
//         fontFamily: null, // keep default sans-serif
//       ),
//       // ✅ IMPORTANT: use "/" as initial route
//       initialRoute: AppRoutes.postLoginRouter,

//       // ✅ IMPORTANT: register "/post-login" here
//       routes: {
//         AppRoutes.postLoginRouter: (_) => const PostLoginRouter(),
//       },
//     );
//   }
// }





