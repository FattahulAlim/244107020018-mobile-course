import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'token_store.dart';  
import '../features/auth/data/auth_repository.dart';

import 'package:dio/dio.dart';
import 'api_client.dart';

final dioProvider = Provider<Dio>((ref) => buildApiClient(
      ref.watch(tokenStoreProvider),
      ref.watch(authRepositoryProvider),
    ));

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository());