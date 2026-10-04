import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/token_store.dart';
import '../data/auth_repository.dart';

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository());