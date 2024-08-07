import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:sishabi/src/shared/versao_widget.dart';

import '../../shared/ec_online.dart';
import 'auth_controller.dart';

class AuthPage extends StatefulWidget {
  final String title;
  const AuthPage({super.key, this.title = 'AuthPage'});
  @override
  AuthPageState createState() => AuthPageState();
}

class AuthPageState extends State<AuthPage> {
  // late final AuthController controller;

  final Color primaryColor = const Color(0xFF4aa0d5);
  final Color backgroundColor = Colors.white;
  final AssetImage backgroundImage =
      const AssetImage('assets/images/full-bloom.png');
  final AssetImage logo = const AssetImage('assets/images/logomarca.png');

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController municipioController = TextEditingController();

  late AuthController controller;
  late String versao = '';

  bool obscurePassToogle = true;

  @override
  void initState() {
    super.initState();

    _carregaVersao();

    controller = context.read<AuthController>();
    // controller = context.watch<AuthController>();
    controller.addListener(() {
      if (controller.state == AuthState.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro na autenticação. Confira suas informações de e-mail/senha/domínio. ${controller.errMsg}',
            ),
          ),
        );
      } else if (controller.state == AuthState.success) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  Future<void> _carregaVersao() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String version = packageInfo.version;
    final String code = packageInfo.buildNumber;
    log('version: $version, code: $code');
    setState(() {
      versao = 'v$version+$code';
    });
  }

  @override
  Widget build(BuildContext context) {
    controller = context.watch<AuthController>();
    // controller = context.read<AuthController>();
    log('build do auth');

    // emailController.text = controller.authRequest.email;
    // passwordController.text = controller.authRequest.password;
    // municipioController.text = controller.authRequest.dominio;

    return Scaffold(
      body: Container(
        // height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: backgroundColor,
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              ClipPath(
                clipper: MyClipper(),
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: backgroundImage,
                      fit: BoxFit.cover,
                    ),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(top: 30, bottom: 30),
                  child: SizedBox(
                    width: 350,
                    child: InkWell(
                      onLongPress: () {
                        emailController.text = 'suporte@e-combr.com.br';
                        municipioController.text = 'playground.sishabi.com.br';
                        controller.authRequest =
                            controller.authRequest.copyWith(
                          email: 'suporte@e-combr.com.br',
                          dominio: 'playground.sishabi.com.br',
                        );
                      },
                      child: Image(
                        image: logo,
                      ),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 40),
                child: Text(
                  'Email',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 20,
                ),
                child: Row(
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 15,
                      ),
                      child: Icon(
                        Icons.person_outline,
                        color: Colors.grey,
                      ),
                    ),
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.grey.withOpacity(0.5),
                      margin: const EdgeInsets.only(right: 10),
                    ),
                    Expanded(
                      child: TextField(
                        autofocus: true,
                        controller: emailController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Insira seu email',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        onChanged: (value) => controller.authRequest =
                            controller.authRequest.copyWith(email: value),
                      ),
                    )
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 40),
                child: Text(
                  'Senha',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 20,
                ),
                child: Row(
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 15,
                      ),
                      child: Icon(
                        Icons.lock_open,
                        color: Colors.grey,
                      ),
                    ),
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.grey.withOpacity(0.5),
                      margin: const EdgeInsets.only(right: 10),
                    ),
                    Expanded(
                      child: TextField(
                        autofocus: true,
                        controller: passwordController,
                        obscureText: obscurePassToogle,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Insira sua senha',
                          hintStyle: TextStyle(color: Colors.grey),
                          suffix: InkWell(
                            onTap: () {
                              log('tap');
                              setState(() {
                                obscurePassToogle = !obscurePassToogle;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 13),
                              child: Icon(
                                obscurePassToogle
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        onChanged: (value) => controller.authRequest =
                            controller.authRequest.copyWith(password: value),
                      ),
                    )
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 40),
                child: Text(
                  'Domínio',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 20,
                ),
                child: Row(
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 15,
                      ),
                      child: Icon(
                        Icons.public,
                        color: Colors.grey,
                      ),
                    ),
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.grey.withOpacity(0.5),
                      margin: const EdgeInsets.only(right: 10),
                    ),
                    Expanded(
                      child: TextField(
                        autofocus: true,
                        controller: municipioController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'geralmente ALGO.sishabi.com.br ',
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                        onChanged: (value) => controller.authRequest =
                            controller.authRequest.copyWith(dominio: value),
                      ),
                    )
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    EcOffline(
                      child: Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            border: Border.all(
                              color: Colors.red,
                            ),
                            borderRadius: const BorderRadius.all(
                              Radius.circular(18),
                            ),
                          ),
                          child: Center(
                            child: InkWell(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Nem adianta clicar ou gastar tempo tentando, é necessária internet para fazer login.',
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                  ),
                                );
                              },
                              child: Row(
                                children: const [
                                  Padding(
                                    padding: EdgeInsets.only(
                                      left: 10,
                                      right: 10,
                                    ),
                                    child: Icon(
                                      Icons.cloud_off_outlined,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Conecte-se a internet para entrar.',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                    EcOnline(
                      child: Expanded(
                        child: TextButton(
                          // shape: new RoundedRectangleBorder(
                          //     borderRadius: new BorderRadius.circular(30.0)),
                          // splashColor: this.primaryColor,
                          // color: this.primaryColor,

                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              // shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: <Widget>[
                                const Padding(
                                  padding: EdgeInsets.only(left: 20),
                                  child: Text(
                                    'ENTRAR',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                Expanded(
                                  child: Container(),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: TextButton(
                                      onPressed: (controller.state ==
                                              AuthState.loading)
                                          ? null
                                          : () async {
                                              debugPrint('entrar');
                                              // if (emailController.text.length < 1 ||
                                              //     passwordController.text.length <
                                              //         1 ||
                                              //     municipioController.text.length < 1)
                                              //   showDialog(
                                              //       context: context,
                                              //       builder: (BuildContext context) {
                                              //         return AlertDialog(
                                              //           title: Text('Atenção!'),
                                              //           content: Text(
                                              //               'Prencha corretamente todas as informações de login!'),
                                              //         );
                                              //       });

                                              await controller
                                                  .loginAction(context);
                                            },
                                      child: (controller.state !=
                                              AuthState.loading)
                                          ? Icon(
                                              Icons.arrow_forward,
                                              color: primaryColor,
                                            )
                                          : const SizedBox(
                                              height: 30,
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          onPressed: () => {},
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
              Center(
                child: Versao(),
              ),
              // Container(
              //   margin: const EdgeInsets.only(top: 20.0),
              //   padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              //   child: new Row(
              //     children: <Widget>[
              //       new Expanded(
              //         child: FlatButton(
              //           shape: new RoundedRectangleBorder(
              //               borderRadius: new BorderRadius.circular(30.0)),
              //           color: Colors.transparent,
              //           child: Container(
              //             padding: const EdgeInsets.only(left: 20.0),
              //             alignment: Alignment.center,
              //             child: Text(
              //               "Não tem uma conta?",
              //               style: TextStyle(color: this.primaryColor),
              //             ),
              //           ),
              //           onPressed: () {
              //             Navigator.pushNamed(context, '/como-acessar');
              //           },
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path p = Path();
    p.lineTo(size.width, 0);
    p.lineTo(size.width, size.height * 0.85);
    p.arcToPoint(
      Offset(0, size.height * 0.85),
      radius: const Radius.elliptical(50, 10),
    );
    p.lineTo(0, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(CustomClipper oldClipper) => true;
}
