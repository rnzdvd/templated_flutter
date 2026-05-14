import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:templated_flutter/core/services/base_api_response.dart';
import 'package:templated_flutter/core/utils/api_config.dart';
import 'package:templated_flutter/store.dart';

class Api {
  final Store _store;
  late Dio _dio;
  late ApiConfig _apiConfig;
  Api({required Store store}) : _store = store {
    _apiConfig = defaultApiConfig;
    _dio = Dio(
      BaseOptions(
        baseUrl: _apiConfig.url ?? '',
        connectTimeout: _apiConfig.timeout,
        receiveTimeout: _apiConfig.timeout,
        headers: _apiConfig.headers,
      ),
    );
  }

  Future<BaseApiResponse<TApiResponseModel>> _parseResponse<TApiResponseModel>(
    Response response,
    TApiResponseModel Function(Map<String, dynamic>) fromJson,
  ) async {
    final data = fromJson(response.data as Map<String, dynamic>);
    return BaseApiResponse(statusCode: response.statusCode ?? 0, data: data);
  }

  @protected
  Future<BaseApiResponse<TApiResponseModel>> delete<TApiResponseModel>(
    String path, {
    required TApiResponseModel Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? params,
  }) async {
    final response = await _dio.delete(path, queryParameters: params);
    return _parseResponse<TApiResponseModel>(response, fromJson);
  }

  @protected
  Future<BaseApiResponse<TApiResponseModel>> get<TApiResponseModel>(
    String path, {
    required TApiResponseModel Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? params,
    Options? options,
  }) async {
    final response = await _dio.get(
      path,
      queryParameters: params,
      options: options,
    );
    return _parseResponse<TApiResponseModel>(response, fromJson);
  }

  @protected
  Future<BaseApiResponse<TApiResponseModel>> post<TApiResponseModel>(
    String path, {
    required TApiResponseModel Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? data,
    Options? options,
  }) async {
    final response = await _dio.post(path, data: data, options: options);
    return _parseResponse<TApiResponseModel>(response, fromJson);
  }

  @protected
  Future<BaseApiResponse<TApiResponseModel>> put<TApiResponseModel>(
    String path, {
    required TApiResponseModel Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? data,
    Options? options,
  }) async {
    final response = await _dio.put(path, data: data, options: options);
    return _parseResponse<TApiResponseModel>(response, fromJson);
  }

  @protected
  Future<BaseApiResponse<TApiResponseModel>> patch<TApiResponseModel>(
    String path, {
    required TApiResponseModel Function(Map<String, dynamic>) fromJson,
    Map<String, dynamic>? data,
    Options? options,
  }) async {
    final response = await _dio.patch(path, data: data, options: options);
    return _parseResponse<TApiResponseModel>(response, fromJson);
  }
}
