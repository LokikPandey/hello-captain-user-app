import 'dart:io';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

const String baseUrl = "https://app.hellocaptain.in/api/customerapi";

Future<Map<String, dynamic>> apiCallBack({
  String method = 'POST',
  required String path,
  Map<String, dynamic> body = const {},
}) async {
  try {
    // Use a local variable for method to avoid mutating the parameter
    String reqMethod = method.isEmpty ? "GET" : method;
    final dio = Dio();
    Response response;
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final String appDocPath = appDocDir.path;
    final jar = PersistCookieJar(
      ignoreExpires: true,
      storage: FileStorage("$appDocPath/.cookies/"),
    );
    dio.interceptors.add(CookieManager(jar));

    final options = Options(headers: {"Authorization": 'Basic YWJjZDo='});

    if (reqMethod == 'POST') {
      response = await dio.post(baseUrl + path, data: body, options: options);
    } else {
      response = await dio.get(baseUrl + path, options: options);
    }
    // log("${response.statusCode}");
    // if (response.statusCode != 200) {
    //   throw "Api Error [Code: ${response.statusCode}]";
    // }
    if (response.data is Map<String, dynamic>) {
      return response.data;
    } else {
      throw "Invalid response format";
    }
  } on DioException catch (e) {
    throw "$path - [DioError] ${e.message}";
  } catch (e) {
    throw "$path - [Error] $e";
  }
}
