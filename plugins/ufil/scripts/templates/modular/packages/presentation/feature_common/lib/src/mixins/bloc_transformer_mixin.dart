import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

mixin BlocTransformerMixin {
  EventTransformer<T> debounceTransformer<T>() {
    return (events, mapper) => events
        .debounceTime(const Duration(milliseconds: 500))
        .switchMap(mapper);
  }
}
