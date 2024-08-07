import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sishabi/src/features/about_page.dart';

class Versao extends StatefulWidget {
  const Versao({super.key, this.clicavel = true, this.licencas = false});

  final clicavel;
  final licencas;

  @override
  State<Versao> createState() => _VersaoState();
}

class _VersaoState extends State<Versao> {
  Future<String> versao() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String version = packageInfo.version;
    final String code = packageInfo.buildNumber;
    return 'v$version+$code';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: InkWell(
        onLongPress: () =>
            widget.licencas ? showLicensePage(context: context) : {},
        onTap: () => widget.clicavel
            ? Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutPage()),
              )
            : {},
        child: FutureBuilder(
          future: versao(),
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            Widget child;
            if (snapshot.hasData) {
              child = Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('${snapshot.data}'),
              );
            } else if (snapshot.hasError) {
              child = Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('Error: ${snapshot.error}'),
              );
            } else {
              child = SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(),
              );
            }
            return Center(
              child: child,
            );
          },
        ),
      ),
    );
  }
}
