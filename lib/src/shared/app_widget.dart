import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:form_builder_validators/localization/l10n.dart';
import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:sishabi/src/shared/preferences_provider.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/auth_page.dart';
import '../features/home/home_page.dart';
import '../features/splash/splash_page.dart';
import 'client_http.dart';
import 'usuario_controller.dart';
import 'vars_controller.dart';

class AppWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    configLoading();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UsuarioController()),
        Provider<ClientHttp>(create: (_) => ClientHttp()),
        ChangeNotifierProvider(create: (_) => PreferencesProvider()),
        Provider<VarsController>(
            create: (context) =>
                VarsController(context.read<PreferencesProvider>())),
        ChangeNotifierProvider(
            create: (context) => AuthController(context.read<ClientHttp>(),
                context.read<PreferencesProvider>())),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,

        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FormBuilderLocalizations.delegate,
        ],

        supportedLocales: const [
          Locale('pt', 'PT'),
          Locale('es', 'ES'),
          Locale('it'),
          Locale('en'),
        ],

        title: 'sisHABI',

        theme: ThemeData(
          useMaterial3: false,
          primarySwatch: Colors.blue,
        ),
        //home: MyHomePage(title: 'Flutter Demo Home Page'),
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashPage(),
          '/auth': (_) => const AuthPage(),
          // '/download': (_) => DownloadPage(),
          '/home': (_) => const MyHomePage(),
          // '/listagem': (_) => ListagemPage(
          //       doque: "asdf",
          //     ),
        },
        builder: EasyLoading.init(
          builder: (context, widget) => OfflineBuilder(
            connectivityBuilder: (
              BuildContext context,
              ConnectivityResult connectivity,
              Widget child,
            ) {
              final bool connected = connectivity != ConnectivityResult.none;
              // print('connected = $connected);

              final UsuarioController usuariosController =
                  context.read<UsuarioController>();

              usuariosController.isNetworkDisponible = connected;

              final ClientHttp clientHttp = context.read<ClientHttp>();
              clientHttp.isNewtorkDisponible = connected;

              return Container(
                color: Theme.of(context).primaryColor,
                child: SafeArea(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      child,
                      Positioned(
                        // height: padding.top,
                        bottom: 0,
                        left: 0,
                        // right: 0.0,
                        child: Container(
                          width: 50,
                          color: connected
                              ? const Color(0xAA00AA44)
                              : const Color(0xAAEE4400),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: FittedBox(
                              child: Text(
                                connected ? 'ONLINE' : 'OFFLINE',
                                style: const TextStyle(
                                  color: Colors.white,
                                  // fontSize: 10,
                                  decorationStyle: TextDecorationStyle.solid,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
              // }
              // return child;
            },
            child: widget,
          ),
        ),
      ),
    );
  }
}

void configLoading() {
  EasyLoading.instance
    ..dismissOnTap = true
    ..userInteractions = false
    ..maskType = EasyLoadingMaskType.black;
}
