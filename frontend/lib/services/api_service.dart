import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:8000/api';
  final Dio _dio = Dio();
  final Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
  };

  // Cache for tokens to avoid reading from disk frequently
  String? _cachedToken;

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }
  
  ApiService._internal() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.contentType = Headers.jsonContentType;
    _dio.options.responseType = ResponseType.json;
    
    // Add auth token interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // In DEV_MODE, no need to add token
        if (AuthService.DEV_MODE) {
          return handler.next(options);
        }
        
        final token = await getAuthToken();
        
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        return handler.next(options);
      },
      onError: (DioException error, handler) {
        // In DEV_MODE, if we get 401, just proceed anyway
        if (AuthService.DEV_MODE && error.response?.statusCode == 401) {
          return handler.resolve(
            Response(
              requestOptions: error.requestOptions,
              data: {'message': 'Bypassed authentication in dev mode'},
              statusCode: 200,
            ),
          );
        }
        
        if (error.response?.statusCode == 401) {
          // Handle unauthorized error (token expired)
          // Implement logout or token refresh here
        }
        return handler.next(error);
      },
    ));
  }
  
  // Authentication
  Future<Map<String, dynamic>> register(String email, String password) async {
    if (AuthService.DEV_MODE) {
      // Return mock success response in dev mode
      return {
        'access_token': 'dev-mode-token',
        'token_type': 'bearer',
        'user': {
          'id': 1,
          'email': 'dev@example.com',
          'is_active': true
        }
      };
    }
    
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
      });
      
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    if (AuthService.DEV_MODE) {
      // Return mock success response in dev mode
      return {
        'access_token': 'dev-mode-token',
        'token_type': 'bearer',
        'user': {
          'id': 1,
          'email': 'dev@example.com',
          'is_active': true
        }
      };
    }
    
    try {
      final response = await _dio.post('/auth/login', data: {
        'username': email, // FastAPI OAuth2 expects 'username'
        'password': password,
      });
      
      final token = response.data['access_token'];
      await saveAuthToken(token);
      
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> firebaseLogin(String firebaseToken) async {
    if (AuthService.DEV_MODE) {
      // Return mock success response in dev mode
      return {
        'access_token': 'dev-mode-token',
        'token_type': 'bearer',
        'user': {
          'id': 1,
          'email': 'dev@example.com',
          'is_active': true
        }
      };
    }
    
    try {
      final response = await _dio.post(
        '/auth/firebase-login',
        options: Options(
          headers: {'Authorization': 'Bearer $firebaseToken'},
        ),
      );
      
      final token = response.data['access_token'];
      await saveAuthToken(token);
      
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  Future<void> logout() async {
    await clearAuthToken();
  }
  
  // User Profile
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _dio.get('/users/me');
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> updateUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final response = await _dio.put('/users/me/preferences', data: preferences);
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  // Arbitrage Opportunities
  Future<List<dynamic>> getArbitrageOpportunities({
    bool activeOnly = true,
    double? minProfit,
  }) async {
    try {
      final response = await _dio.get('/arbitrage/opportunities', queryParameters: {
        'active_only': activeOnly,
        if (minProfit != null) 'min_profit': minProfit,
      });
      
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      return [];
    }
  }
  
  Future<Map<String, dynamic>> getArbitrageOpportunityDetails(int id) async {
    try {
      final response = await _dio.get('/arbitrage/opportunities/$id');
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> calculateArbitrage(
    List<Map<String, dynamic>> oddsData, {
    double? totalStake,
  }) async {
    try {
      // Process the odds data to ensure market information is properly formatted
      final processedOddsData = oddsData.map((odds) {
        // Create a copy of the original data
        Map<String, dynamic> processedOdds = Map.from(odds);
        
        // Extract market type and parameters if present
        final String? marketType = odds['market_type'];
        final String? marketParams = odds['market_params'];
        
        // Format outcome for over/under markets if needed
        if (marketType == 'over_under' && marketParams != null) {
          // Ensure outcome includes the goal line value if not already present
          final String outcome = processedOdds['outcome'] ?? '';
          if (outcome.toLowerCase().contains('over') && !outcome.contains(marketParams)) {
            processedOdds['outcome'] = 'over';
          } else if (outcome.toLowerCase().contains('under') && !outcome.contains(marketParams)) {
            processedOdds['outcome'] = 'under';
          }
        }
        
        return processedOdds;
      }).toList();
      
      final response = await _dio.post(
        '/arbitrage/calculate',
        data: {
          'odds_data': processedOddsData,
          if (totalStake != null) 'total_stake': totalStake,
        },
      );
      
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  // Notifications
  Future<List<dynamic>> getUserNotifications({bool unreadOnly = false}) async {
    try {
      final response = await _dio.get('/arbitrage/notifications', queryParameters: {
        'unread_only': unreadOnly,
      });
      
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      return [];
    }
  }
  
  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      await _dio.put('/arbitrage/notifications/$notificationId', data: {
        'is_read': true,
      });
    } on DioException catch (e) {
      _handleError(e);
    }
  }
  
  Future<void> markAllNotificationsAsRead() async {
    try {
      await _dio.put('/arbitrage/notifications/read-all');
    } on DioException catch (e) {
      _handleError(e);
    }
  }
  
  // Bookmakers
  Future<List<dynamic>> getBookmakers() async {
    try {
      final response = await _dio.get('/bookmakers/');
      return response.data;
    } on DioException catch (e) {
      _handleError(e);
      return [];
    }
  }
  
  void _handleError(DioException error) {
    if (error.response != null) {
      print('API Error: ${error.response!.statusCode} - ${error.response!.data}');
    } else {
      print('API Error: ${error.message}');
    }
  }

  // Get the authentication token from shared preferences
  Future<String?> getAuthToken() async {
    if (_cachedToken != null) return _cachedToken;
    
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('auth_token');
    return _cachedToken;
  }

  // Save the authentication token to shared preferences
  Future<void> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _cachedToken = token;
  }

  // Clear the authentication token
  Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _cachedToken = null;
  }

  // Add authorization header if token is provided
  Map<String, String> _getHeaders({String? token}) {
    final headers = Map<String, String>.from(_defaultHeaders);
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  // Handle response
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    } else {
      final error = json.decode(response.body);
      final message = error['detail'] ?? 'Unknown error occurred';
      
      if (response.statusCode == 401) {
        // Clear token on unauthorized
        clearAuthToken();
      }
      
      throw Exception('API Error: $message');
    }
  }

  // GET request
  Future<http.Response> get(String path, {String? token}) async {
    final url = Uri.parse('$_baseUrl$path');
    final resolvedToken = token ?? await getAuthToken();
    
    try {
      final response = await http.get(
        url,
        headers: _getHeaders(token: resolvedToken),
      );
      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('GET request failed: $e');
      }
      rethrow;
    }
  }

  // POST request
  Future<http.Response> post(String path, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    final url = Uri.parse('$_baseUrl$path');
    final resolvedToken = token ?? await getAuthToken();
    
    try {
      final response = await http.post(
        url,
        headers: _getHeaders(token: resolvedToken),
        body: json.encode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('POST request failed: $e');
      }
      rethrow;
    }
  }

  // PUT request
  Future<http.Response> put(String path, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    final url = Uri.parse('$_baseUrl$path');
    final resolvedToken = token ?? await getAuthToken();
    
    try {
      final response = await http.put(
        url,
        headers: _getHeaders(token: resolvedToken),
        body: json.encode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('PUT request failed: $e');
      }
      rethrow;
    }
  }

  // DELETE request
  Future<http.Response> delete(String path, {String? token}) async {
    final url = Uri.parse('$_baseUrl$path');
    final resolvedToken = token ?? await getAuthToken();
    
    try {
      final response = await http.delete(
        url,
        headers: _getHeaders(token: resolvedToken),
      );
      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) {
        print('DELETE request failed: $e');
      }
      rethrow;
    }
  }
} 