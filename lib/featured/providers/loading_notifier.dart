import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoadingState {
  final Map<String, bool> loadingStates;

  LoadingState({Map<String, bool>? loadingStates})
      : loadingStates = loadingStates ?? {};

  bool isLoading(String feature) {
    return loadingStates[feature] ?? false;
  }

  LoadingState copyWith({
    Map<String, bool>? loadingStates,
  }) {
    return LoadingState(
      loadingStates: loadingStates ?? this.loadingStates,
    );
  }
}

class LoadingNotifier extends StateNotifier<LoadingState> {
  LoadingNotifier() : super(LoadingState());

  void setLoading(String feature, bool value) {
    state = state.copyWith(
      loadingStates: {...state.loadingStates, feature: value},
    );
  }

  bool isLoading(String feature) {
    return state.isLoading(feature);
  }
}

// Global Provider
