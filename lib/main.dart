import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:newsai/models/news_category.dart';
import 'package:newsai/views/auth/auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:newsai/firebase_options.dart';
import 'package:newsai/views/inner_screens/profile.dart';
import 'package:newsai/views/inner_screens/search_result.dart';
import 'package:newsai/views/inner_screens/settings.dart';
import 'package:newsai/views/intro_screen/intro_screen.dart';
import 'package:newsai/views/inner_screens/bookmark.dart';
import 'package:newsai/views/nav_screen/home.dart';
import 'package:newsai/views/nav_screen/side_page.dart';
import 'package:newsai/views/splash_screen.dart';
import 'package:newsai/controller/services/bookmark_services.dart';
import 'package:newsai/controller/services/news_services.dart';
import 'package:newsai/controller/bloc/bookmark_bloc/bookmark_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Create a class to manage authentication state
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Check if user is signed in
  static bool isUserSignedIn() {
    return _auth.currentUser != null;
  }
}

// Create a router notifier to handle authentication state changes
class AuthNotifier extends ChangeNotifier {
  AuthNotifier() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      notifyListeners();
    });
  }
}

// Create the router with auth state handling
final _authNotifier = AuthNotifier();
final _routes = GoRouter(
  refreshListenable: _authNotifier,
  initialLocation: '/intro',
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) {
        return const SplashScreen();
      },
    ),
    GoRoute(
      path: '/auth',
      name: 'auth',
      builder: (context, state) {
        return const AuthScreen();
      },
    ),
    GoRoute(
      path: '/intro',
      name: 'intro',
      builder: (context, state) {
        return const IntroductionScreen();
      },
    ),
    GoRoute(
      path: '/sidepage',
      name: 'sidepage',
      pageBuilder:
          (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const SidePage(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              const begin = Offset(-1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOut;
              return SlideTransition(
                position: Tween(
                  begin: begin,
                  end: end,
                ).chain(CurveTween(curve: curve)).animate(animation),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 225),
          ),
      routes: [
        GoRoute(
          path: 'bookmark',
          name: 'bookmark',
          pageBuilder:
              (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const BookmarkScreen(),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  // Combine scale and fade animations
                  return Align(
                    alignment: Alignment.center,
                    child: FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: animation.drive(
                          Tween<double>(
                            begin: 0.0,
                            end: 1.0,
                          ).chain(CurveTween(curve: Curves.easeInOutQuad)),
                        ),
                        child: child,
                      ),
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 225),
              ),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          pageBuilder:
              (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: const SettingsScreen(),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  return Align(
                    alignment: Alignment.center,
                    child: FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: animation.drive(
                          Tween<double>(
                            begin: 0.0,
                            end: 1.0,
                          ).chain(CurveTween(curve: Curves.easeInOutQuad)),
                        ),
                        child: child,
                      ),
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 225),
              ),
        ),
        GoRoute(
          path: '/searchResults',
          name: 'searchResults',
          pageBuilder:
              (context, state) => CustomTransitionPage(
                key: state.pageKey,
                child: SearchResultsScreen(
                  query:
                      state
                          .uri
                          .queryParameters['query']!, // Only query parameter
                ),
                transitionsBuilder: (
                  context,
                  animation,
                  secondaryAnimation,
                  child,
                ) {
                  // Combine scale and fade animations
                  return Align(
                    alignment: Alignment.center,
                    child: FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: animation.drive(
                          Tween<double>(
                            begin: 0.0,
                            end: 1.0,
                          ).chain(CurveTween(curve: Curves.easeInOutQuad)),
                        ),
                        child: child,
                      ),
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 225),
              ),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => ProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/home/:category',
      name: 'home',
      pageBuilder: (context, state) {
        final category = NewsCategory.fromIndex(
          int.parse(state.pathParameters['category'] ?? '0'),
        );
        return CustomTransitionPage(
          key: state.pageKey,
          child: HomeScreen(category: category),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOut;
            return SlideTransition(
              position: Tween(
                begin: begin,
                end: end,
              ).chain(CurveTween(curve: curve)).animate(animation),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 225),
        );
      },
    ),
  ],
  // Add redirect logic to handle authentication state
  redirect: (context, state) {
    // Allow access to splash screen
    if (state.matchedLocation == '/splash') return null;
    
    // Check for routes that should be accessible without authentication
    final allowedPaths = ['/auth', '/intro'];
    if (allowedPaths.contains(state.matchedLocation)) return null;
    
    // If user is not signed in, redirect to auth
    if (!AuthService.isUserSignedIn()) {
      return '/auth';
    }
    
    // Allow access to authenticated routes
    return null;
  },
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final bookmarkRepository = BookmarkServices();
  final newsService = NewsService();
  await bookmarkRepository.initialize();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await dotenv.load(fileName: ".env");

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: newsService),
        RepositoryProvider.value(value: bookmarkRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (context) => BookmarkBloc(bookmarkRepository)),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Brevity',
      debugShowCheckedModeBanner: false,
      routerConfig: _routes,
    );
  }
}