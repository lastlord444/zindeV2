// lib/main.dart
// ZindeAI V2.0 - Ana giriş noktası

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/di/injection_container.dart' as di;
import 'presentation/bloc/home/home_bloc.dart';
import 'presentation/bloc/home/home_event.dart';
import 'presentation/bloc/profil/profil_bloc.dart';
import 'presentation/pages/home_page_yeni.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables for Supabase
  // Web'de .env dosyası yüklenemeyebilir, hata yakalanmalı
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ .env dosyası yüklenemedi (Web için normal): $e');
    }
  }

  // Bağımlılıkları başlat (Supabase dahil)
  await di.initDependencies();

  runApp(const ZindeAIApp());
}

class ZindeAIApp extends StatelessWidget {
  const ZindeAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeBloc>(
          create: (_) => di.sl<HomeBloc>()..add(const LoadHomePage()),
        ),
        BlocProvider<ProfilBloc>(
          create: (_) => di.sl<ProfilBloc>(),
        ),
      ],
      child: MaterialApp(
        title: 'ZindeAI',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C63FF),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'Inter',
        ),
        home: const YeniHomePage(),
      ),
    );
  }
}
