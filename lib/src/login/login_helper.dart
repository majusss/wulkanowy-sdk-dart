import 'dart:core';
import 'dart:convert';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;

class LoginHelper {
  late Dio _dio;
  final _cookieJar = CookieJar();
  final String schema;
  final String host;
  final String symbol;
  late String firstStepReturnUrl;
  late String _schoolId;

  LoginHelper(this.schema, this.host, this.symbol) {
    final targetRealm =
        encode('$schema://uonetplus.$host/$symbol/LoginEndpoint.aspx');
    final intermediateRealmPath = StringBuffer()
      ..write('/$symbol/FS/LS')
      ..write('?wa=wsignin1.0')
      ..write('&wtrealm=$targetRealm')
      ..write("&wctx=${encode("auth=uonet")}");
    final intermediateRealm =
        encode('$schema://uonetplus-logowanie.$host$intermediateRealmPath');
    final returnUrl = StringBuffer()
      ..write('/$symbol/FS/LS')
      ..write('?wa=wsignin1.0')
      ..write('&wtrealm=$intermediateRealm')
      ..write("&wctx=${encode("rm=0&id=")}")
      ..write('&wct=${encode(DateTime.now().toIso8601String())}');
    firstStepReturnUrl = returnUrl.toString();
    _dio = Dio();
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  Future<String> login(String name, String password) async {
    final cert = await sendCredentials(name, password);
    await sendCertificate(cert);
    final home = parse(
        (await _dio.get('$schema://uonetplus.$host/$symbol/Start.mvc')).data);

    final students = home.querySelector('#idAppUczenExt');

    if (students == null) {
      final schoolId = home
          .querySelectorAll('.appLink')
          .firstWhere(
              (e) => e.querySelector('a')?.attributes['title'] == 'Uczeń',
              orElse: () => Element.tag('a'))
          .querySelector('a')
          ?.attributes['href'];

      if (schoolId != null) {
        _schoolId = Uri.parse(schoolId).pathSegments[1];
      }
    } else {
      final schools = students.querySelectorAll('a');
      // TODO: Implement multiple students support
      print(
          'Schools: ${schools.map((e) => e.attributes['title']?.trim()).join(', ')}');
    }

    return home.querySelector('.user-info')?.text.trim() ??
        'No user info found';
  }

  Future<Document> sendCredentials(String name, String password) {
    final loginName = name.split('||')[0];

    return sendStandard(loginName, password);
  }

  Future<Document> sendStandard(String name, String password) async {
    final baseUrl = '$schema://cufs.$host';

    final response = await _dio.post(
        '$baseUrl/$symbol/Account/LogOn?ReturnUrl=${encode(firstStepReturnUrl)}',
        data: {'LoginName': name, 'Password': password},
        options: Options(followRedirects: false, validateStatus: (_) => true));

    final check = parse(response.data);
    if (check.querySelector('.ErrorMessage') != null) {
      throw Exception(check.querySelector('.ErrorMessage')?.text.trim());
    }

    final location = response.headers['location']?.first;
    if (location == null) {
      throw Exception('Login request did not return a location header!');
    }

    final secondResponse = await _dio.get('$schema://cufs.$host/$location',
        options: Options(followRedirects: false, validateStatus: (_) => true));

    return parse(secondResponse.data);
  }

  Future<Document> sendCertificate(Document cert) async {
    final formAction =
        cert.querySelector('form[name=hiddenform]')?.attributes['action'];

    if (formAction == null) {
      throw Exception('Form action is null!');
    }

    final firstCert = await _dio.post(formAction,
        data: {
          'wa': cert.querySelector('input[name=wa]')?.attributes['value'] ?? '',
          'wresult':
              cert.querySelector('input[name=wresult]')?.attributes['value'] ??
                  '',
          'wctx':
              cert.querySelector('input[name=wctx]')?.attributes['value'] ?? ''
        },
        options: Options(headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        }, followRedirects: false, validateStatus: (_) => true));

    final finalCert = parse(firstCert.data);

    final finalFormAction =
        finalCert.querySelector('form[name=hiddenform]')?.attributes['action'];

    if (finalFormAction == null) {
      throw Exception('Form action is null!');
    }

    final finalCertRes = await _dio.post(finalFormAction,
        data: {
          'wa':
              finalCert.querySelector('input[name=wa]')?.attributes['value'] ??
                  '',
          'wresult': finalCert
                  .querySelector('input[name=wresult]')
                  ?.attributes['value'] ??
              '',
          'wctx': finalCert
                  .querySelector('input[name=wctx]')
                  ?.attributes['value'] ??
              ''
        },
        options: Options(headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        }, followRedirects: true, validateStatus: (_) => true));

    return parse(finalCertRes.data);
  }

  String encode(String url) {
    return Uri.encodeComponent(url);
  }

  Future<Map<String, String>> getQrData() async {
    final res = await _dio.get(
        'http://uonetplus-uczen.$host/$symbol/$_schoolId/RejestracjaUrzadzeniaToken.mvc/Get');
    final jsonData = json.decode(res.data)['data'];
    return {
      'pin': jsonData['PIN'],
      'symbol': jsonData['CustomerGroup'],
      'token': jsonData['TokenKey']
    };
  }
}
