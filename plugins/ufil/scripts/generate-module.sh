#!/bin/bash
# UFIL — Generate feature module
# Usage: ./generate-module.sh <module_name> [--modular|--single] [--layer domain|data|presentation|all]
# Example: ./generate-module.sh tenant --modular --layer all
# Example: ./generate-module.sh payment --single
#
# Prerequisites: FVM must be installed (dart pub global activate fvm)
# Dependencies are fetched from pub.dev automatically (no hardcoded versions).

set -e

MODULE_NAME="${1:?Usage: generate-module.sh <module_name> [--modular|--single] [--layer domain|data|presentation|all]}"
PROJECT_TYPE="auto"
LAYER="all"

shift
while [[ $# -gt 0 ]]; do
  case $1 in
    --modular) PROJECT_TYPE="modular"; shift ;;
    --single) PROJECT_TYPE="single"; shift ;;
    --layer) LAYER="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Auto-detect project type
if [ "$PROJECT_TYPE" = "auto" ]; then
  if [ -d "packages" ]; then
    PROJECT_TYPE="modular"
  else
    PROJECT_TYPE="single"
  fi
fi

# ========================================
# PREREQUISITES
# ========================================
if ! command -v fvm &> /dev/null; then
  echo "❌ FVM is required. Install: dart pub global activate fvm"
  exit 1
fi

# Detect SDK constraint from root pubspec.yaml or FVM
SDK_CONSTRAINT=""
if [ -f "pubspec.yaml" ]; then
  SDK_CONSTRAINT=$(grep -E '^\s+sdk:' pubspec.yaml | head -1 | awk '{print $2}' | tr -d "'\"")
fi
if [ -z "$SDK_CONSTRAINT" ]; then
  DART_SDK_FULL=$(fvm dart --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  DART_SDK_MAJOR_MINOR=$(echo "$DART_SDK_FULL" | cut -d'.' -f1,2)
  SDK_CONSTRAINT="^${DART_SDK_MAJOR_MINOR}.0"
fi

# Helper: add deps using fvm dart pub add (always fetches latest from pub.dev)
pub_add() {
  fvm dart pub add "$@" 2>&1 | tail -1
}
pub_add_dev() {
  fvm dart pub add --dev "$@" 2>&1 | tail -1
}

# Convert module name to PascalCase
MODULE_PASCAL=$(echo "$MODULE_NAME" | sed -r 's/(^|_)([a-z])/\U\2/g' 2>/dev/null || echo "$MODULE_NAME" | perl -pe 's/(^|_)(\w)/\U$2/g')

PROJECT_ROOT="$(pwd)"

echo "🏗️ Generating module: $MODULE_NAME (${PROJECT_TYPE}, layer: ${LAYER})"

# ========================================
# MODULAR PROJECT
# ========================================
if [ "$PROJECT_TYPE" = "modular" ]; then

  # --- DOMAIN ---
  if [ "$LAYER" = "all" ] || [ "$LAYER" = "domain" ]; then
    echo "  📦 domain_${MODULE_NAME}..."
    BASE="packages/domain/domain_${MODULE_NAME}"
    mkdir -p "$BASE/lib/src"/{models,repositories,use_cases,config,di}

    # Minimal pubspec with path deps only
    cat > "$BASE/pubspec.yaml" << EOF
name: domain_${MODULE_NAME}
description: Domain layer for ${MODULE_NAME}
version: 1.0.0
publish_to: 'none'
resolution: workspace

environment:
  sdk: $SDK_CONSTRAINT

dependencies:
  domain_common:
    path: ../domain_common
  library_common:
    path: ../../library/library_common
EOF

    cat > "$BASE/lib/domain_${MODULE_NAME}.dart" << EOF
export 'src/models/${MODULE_NAME}_model.dart';
export 'src/repositories/${MODULE_NAME}_repository.dart';
export 'src/use_cases/get_${MODULE_NAME}_usecase.dart';
export 'src/config/domain_${MODULE_NAME}_config.dart';
EOF

    cat > "$BASE/lib/src/models/${MODULE_NAME}_model.dart" << EOF
import 'package:freezed_annotation/freezed_annotation.dart';

part '${MODULE_NAME}_model.freezed.dart';

@freezed
sealed class ${MODULE_PASCAL}Model with _\$${MODULE_PASCAL}Model {
  const factory ${MODULE_PASCAL}Model({
    @Default('') String id,
    @Default('') String name,
  }) = _${MODULE_PASCAL}Model;
}
EOF

    cat > "$BASE/lib/src/models/get_${MODULE_NAME}_list_result.dart" << EOF
import 'package:domain_common/domain_common.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '${MODULE_NAME}_model.dart';

part 'get_${MODULE_NAME}_list_result.freezed.dart';

@freezed
abstract class Get${MODULE_PASCAL}ListResult with _\$Get${MODULE_PASCAL}ListResult {
  const factory Get${MODULE_PASCAL}ListResult({
    @Default(Failure.noFailure()) Failure failure,
    @Default([]) List<${MODULE_PASCAL}Model> items,
  }) = _Get${MODULE_PASCAL}ListResult;
}
EOF

    cat > "$BASE/lib/src/repositories/${MODULE_NAME}_repository.dart" << EOF
import 'package:domain_${MODULE_NAME}/src/models/get_${MODULE_NAME}_list_result.dart';

abstract class ${MODULE_PASCAL}Repository {
  Future<Get${MODULE_PASCAL}ListResult> get${MODULE_PASCAL}List();
}
EOF

    cat > "$BASE/lib/src/use_cases/get_${MODULE_NAME}_usecase.dart" << EOF
import 'package:injectable/injectable.dart';
import 'package:domain_${MODULE_NAME}/src/models/get_${MODULE_NAME}_list_result.dart';
import 'package:domain_${MODULE_NAME}/src/repositories/${MODULE_NAME}_repository.dart';

@lazySingleton
class Get${MODULE_PASCAL}Usecase {
  const Get${MODULE_PASCAL}Usecase(this._repository);
  final ${MODULE_PASCAL}Repository _repository;

  Future<Get${MODULE_PASCAL}ListResult> call() {
    return _repository.get${MODULE_PASCAL}List();
  }
}
EOF

    cat > "$BASE/lib/src/config/domain_${MODULE_NAME}_config.dart" << EOF
import 'package:library_common/library_common.dart';
import 'package:domain_${MODULE_NAME}/src/di/di.dart';

class Domain${MODULE_PASCAL}Config extends AppConfig {
  Domain${MODULE_PASCAL}Config._();
  static final Domain${MODULE_PASCAL}Config _instance = Domain${MODULE_PASCAL}Config._();
  static Domain${MODULE_PASCAL}Config getInstance() {
    return _instance;
  }

  @override
  Future<bool> config({required String env}) async {
    configureInjection(env: env);
    return true;
  }
}
EOF

    cat > "$BASE/lib/src/di/di.dart" << 'EOF'
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'di.config.dart';

final getIt = GetIt.instance;

@injectableInit
void configureInjection({required String env}) {
  getIt.init(environment: env);
}
EOF

    cat > "$BASE/build.yaml" << 'EOF'
targets:
  $default:
    builders:
      freezed:
        generate_for:
          - lib/src/models/**
      injectable_generator|injectable_builder:
        generate_for:
          - lib/src/use_cases/**
          - lib/src/di/di.dart
EOF

    # Install deps from pub.dev
    echo "    📡 Installing domain deps..."
    cd "$PROJECT_ROOT/$BASE"
    pub_add freezed_annotation get_it injectable
    pub_add_dev build_runner freezed injectable_generator
    cd "$PROJECT_ROOT"
  fi

  # --- DATA ---
  if [ "$LAYER" = "all" ] || [ "$LAYER" = "data" ]; then
    echo "  📦 data_${MODULE_NAME}..."
    BASE="packages/data/data_${MODULE_NAME}"
    mkdir -p "$BASE/lib/src"/{models,mappers,data_sources,repositories,config,di}

    cat > "$BASE/pubspec.yaml" << EOF
name: data_${MODULE_NAME}
description: Data layer for ${MODULE_NAME}
version: 1.0.0
publish_to: 'none'
resolution: workspace

environment:
  sdk: $SDK_CONSTRAINT

dependencies:
  domain_${MODULE_NAME}:
    path: ../../domain/domain_${MODULE_NAME}
  domain_common:
    path: ../../domain/domain_common
  data_common:
    path: ../data_common
  library_common:
    path: ../../library/library_common
EOF

    cat > "$BASE/lib/data_${MODULE_NAME}.dart" << EOF
export 'src/config/data_${MODULE_NAME}_config.dart';
EOF

    cat > "$BASE/lib/src/models/${MODULE_NAME}_dto.dart" << EOF
import 'package:freezed_annotation/freezed_annotation.dart';

part '${MODULE_NAME}_dto.freezed.dart';
part '${MODULE_NAME}_dto.g.dart';

@freezed
abstract class ${MODULE_PASCAL}Dto with _\$${MODULE_PASCAL}Dto {
  const factory ${MODULE_PASCAL}Dto({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'name') String? name,
  }) = _${MODULE_PASCAL}Dto;

  factory ${MODULE_PASCAL}Dto.fromJson(Map<String, dynamic> json) {
    return _\$${MODULE_PASCAL}DtoFromJson(json);
  }
}
EOF

    cat > "$BASE/lib/src/models/get_${MODULE_NAME}_list_response.dart" << EOF
import 'package:freezed_annotation/freezed_annotation.dart';
import '${MODULE_NAME}_dto.dart';

part 'get_${MODULE_NAME}_list_response.freezed.dart';
part 'get_${MODULE_NAME}_list_response.g.dart';

@freezed
abstract class Get${MODULE_PASCAL}ListResponse with _\$Get${MODULE_PASCAL}ListResponse {
  const factory Get${MODULE_PASCAL}ListResponse({
    @JsonKey(name: '${MODULE_NAME}s') List<${MODULE_PASCAL}Dto>? ${MODULE_NAME}s,
    @JsonKey(name: 'total') int? total,
  }) = _Get${MODULE_PASCAL}ListResponse;

  factory Get${MODULE_PASCAL}ListResponse.fromJson(Map<String, dynamic> json) {
    return _\$Get${MODULE_PASCAL}ListResponseFromJson(json);
  }
}
EOF

    cat > "$BASE/lib/src/mappers/${MODULE_NAME}_model_mapper.dart" << EOF
import 'package:domain_${MODULE_NAME}/domain_${MODULE_NAME}.dart';
import 'package:injectable/injectable.dart';
import 'package:data_${MODULE_NAME}/src/models/${MODULE_NAME}_dto.dart';

@lazySingleton
class ${MODULE_PASCAL}ModelMapper {
  ${MODULE_PASCAL}Model mapFromData(${MODULE_PASCAL}Dto? data) {
    return ${MODULE_PASCAL}Model(
      id: data?.id ?? '',
      name: data?.name ?? '',
    );
  }
}
EOF

    cat > "$BASE/lib/src/mappers/get_${MODULE_NAME}_list_result_mapper.dart" << EOF
import 'package:domain_${MODULE_NAME}/domain_${MODULE_NAME}.dart';
import 'package:injectable/injectable.dart';
import 'package:data_${MODULE_NAME}/src/models/get_${MODULE_NAME}_list_response.dart';
import 'package:data_${MODULE_NAME}/src/mappers/${MODULE_NAME}_model_mapper.dart';

@lazySingleton
class Get${MODULE_PASCAL}ListResultMapper {
  final ${MODULE_PASCAL}ModelMapper _${MODULE_NAME}ModelMapper;

  Get${MODULE_PASCAL}ListResultMapper(this._${MODULE_NAME}ModelMapper);

  Get${MODULE_PASCAL}ListResult mapFromData(Get${MODULE_PASCAL}ListResponse? data) {
    return Get${MODULE_PASCAL}ListResult(
      items: (data?.${MODULE_NAME}s ?? []).map(_${MODULE_NAME}ModelMapper.mapFromData).toList(),
      total: data?.total ?? 0,
    );
  }
}
EOF

    cat > "$BASE/lib/src/data_sources/${MODULE_NAME}_remote_datasource.dart" << EOF
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:data_${MODULE_NAME}/src/models/get_${MODULE_NAME}_list_response.dart';

@lazySingleton
class ${MODULE_PASCAL}RemoteDatasource {
  const ${MODULE_PASCAL}RemoteDatasource(this._dio);
  final Dio _dio;

  Future<Get${MODULE_PASCAL}ListResponse> get${MODULE_PASCAL}List() async {
    final response = await _dio.get('/${MODULE_NAME}s');
    return Get${MODULE_PASCAL}ListResponse.fromJson(response.data as Map<String, dynamic>);
  }
}
EOF

    cat > "$BASE/lib/src/repositories/${MODULE_NAME}_repository_impl.dart" << EOF
import 'package:data_common/data_common.dart';
import 'package:domain_${MODULE_NAME}/domain_${MODULE_NAME}.dart';
import 'package:injectable/injectable.dart';
import 'package:data_${MODULE_NAME}/src/data_sources/${MODULE_NAME}_remote_datasource.dart';
import 'package:data_${MODULE_NAME}/src/mappers/get_${MODULE_NAME}_list_result_mapper.dart';

@LazySingleton(as: ${MODULE_PASCAL}Repository)
class ${MODULE_PASCAL}RepositoryImpl
    with FailureHandlerMixin
    implements ${MODULE_PASCAL}Repository {
  const ${MODULE_PASCAL}RepositoryImpl(this._datasource, this._resultMapper);
  final ${MODULE_PASCAL}RemoteDatasource _datasource;
  final Get${MODULE_PASCAL}ListResultMapper _resultMapper;

  @override
  Future<Get${MODULE_PASCAL}ListResult> get${MODULE_PASCAL}List() async {
    try {
      final response = await _datasource.get${MODULE_PASCAL}List();
      return _resultMapper.mapFromData(response);
    } catch (e) {
      return Get${MODULE_PASCAL}ListResult(failure: mapToFailure(e));
    }
  }
}
EOF

    cat > "$BASE/lib/src/config/data_${MODULE_NAME}_config.dart" << EOF
import 'package:library_common/library_common.dart';
import 'package:data_${MODULE_NAME}/src/di/di.dart';

class Data${MODULE_PASCAL}Config extends AppConfig {
  Data${MODULE_PASCAL}Config._();
  static final Data${MODULE_PASCAL}Config _instance = Data${MODULE_PASCAL}Config._();
  static Data${MODULE_PASCAL}Config getInstance() {
    return _instance;
  }

  @override
  Future<bool> config({required String env}) async {
    configureInjection(env: env);
    return true;
  }
}
EOF

    cat > "$BASE/lib/src/di/di.dart" << 'EOF'
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'di.config.dart';

final getIt = GetIt.instance;

@injectableInit
void configureInjection({required String env}) {
  getIt.init(environment: env);
}
EOF

    cat > "$BASE/build.yaml" << 'EOF'
targets:
  $default:
    builders:
      freezed:
        generate_for:
          - lib/src/models/**
      json_serializable:
        generate_for:
          - lib/src/models/**
      injectable_generator|injectable_builder:
        generate_for:
          - lib/src/data_sources/**
          - lib/src/mappers/**
          - lib/src/repositories/**
          - lib/src/di/di.dart
EOF

    # Install deps from pub.dev
    echo "    📡 Installing data deps..."
    cd "$PROJECT_ROOT/$BASE"
    pub_add dio freezed_annotation json_annotation get_it injectable
    pub_add_dev build_runner freezed json_serializable injectable_generator
    cd "$PROJECT_ROOT"
  fi

  # --- PRESENTATION ---
  if [ "$LAYER" = "all" ] || [ "$LAYER" = "presentation" ]; then
    echo "  📦 feature_${MODULE_NAME}..."
    BASE="packages/presentation/feature_${MODULE_NAME}"
    mkdir -p "$BASE/lib/src"/{blocs/${MODULE_NAME},pages,config,di}

    cat > "$BASE/pubspec.yaml" << EOF
name: feature_${MODULE_NAME}
description: Presentation layer for ${MODULE_NAME}
version: 1.0.0
publish_to: 'none'
resolution: workspace

environment:
  sdk: $SDK_CONSTRAINT

dependencies:
  flutter:
    sdk: flutter
  domain_${MODULE_NAME}:
    path: ../../domain/domain_${MODULE_NAME}
  domain_common:
    path: ../../domain/domain_common
  feature_common:
    path: ../feature_common
  library_common:
    path: ../../library/library_common
EOF

    cat > "$BASE/lib/feature_${MODULE_NAME}.dart" << EOF
export 'src/config/feature_${MODULE_NAME}_config.dart';
EOF

    cat > "$BASE/lib/src/blocs/${MODULE_NAME}/${MODULE_NAME}_bloc.dart" << EOF
import 'package:domain_${MODULE_NAME}/domain_${MODULE_NAME}.dart';
import 'package:domain_common/domain_common.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part '${MODULE_NAME}_bloc.freezed.dart';
part '${MODULE_NAME}_event.dart';
part '${MODULE_NAME}_state.dart';

@injectable
class ${MODULE_PASCAL}Bloc extends Bloc<${MODULE_PASCAL}Event, ${MODULE_PASCAL}State> {
  ${MODULE_PASCAL}Bloc(this._get${MODULE_PASCAL}Usecase) : super(const ${MODULE_PASCAL}State()) {
    on<_InitEvent>(_initEvent);
  }

  final Get${MODULE_PASCAL}Usecase _get${MODULE_PASCAL}Usecase;

  Future<void> _initEvent(
    _InitEvent event,
    Emitter<${MODULE_PASCAL}State> emit,
  ) async {
    emit(state.copyWith(${MODULE_NAME}State: const Get${MODULE_PASCAL}State.loading()));
    final failure = await _get${MODULE_PASCAL}Usecase();
    switch (failure) {
      case NoFailure():
        // TODO: Load data and emit done state
        emit(state.copyWith(${MODULE_NAME}State: const Get${MODULE_PASCAL}State.done([])));
      default:
        emit(state.copyWith(${MODULE_NAME}State: Get${MODULE_PASCAL}State.error(failure)));
    }
  }
}
EOF

    cat > "$BASE/lib/src/blocs/${MODULE_NAME}/${MODULE_NAME}_event.dart" << EOF
part of '${MODULE_NAME}_bloc.dart';

@freezed
abstract class ${MODULE_PASCAL}Event with _\$${MODULE_PASCAL}Event {
  const factory ${MODULE_PASCAL}Event.init() = _InitEvent;
}
EOF

    cat > "$BASE/lib/src/blocs/${MODULE_NAME}/${MODULE_NAME}_state.dart" << EOF
part of '${MODULE_NAME}_bloc.dart';

@freezed
abstract class ${MODULE_PASCAL}State with _\$${MODULE_PASCAL}State {
  const factory ${MODULE_PASCAL}State({
    @Default(Get${MODULE_PASCAL}State.idle()) Get${MODULE_PASCAL}State ${MODULE_NAME}State,
  }) = _${MODULE_PASCAL}State;
}

@freezed
abstract class Get${MODULE_PASCAL}State with _\$Get${MODULE_PASCAL}State {
  const factory Get${MODULE_PASCAL}State.idle() = _Get${MODULE_PASCAL}IdleState;
  const factory Get${MODULE_PASCAL}State.loading() = Get${MODULE_PASCAL}LoadingState;
  const factory Get${MODULE_PASCAL}State.done(List<${MODULE_PASCAL}Model> items) = Get${MODULE_PASCAL}DoneState;
  const factory Get${MODULE_PASCAL}State.error(Failure failure) = Get${MODULE_PASCAL}ErrorState;
}
EOF

    cat > "$BASE/lib/src/pages/${MODULE_NAME}_page.dart" << EOF
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

@RoutePage()
class ${MODULE_PASCAL}Page extends StatelessWidget {
  const ${MODULE_PASCAL}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${MODULE_PASCAL}',
          style: TextStyle(fontSize: 18.sp),
        ),
      ),
      body: Center(
        child: Text(
          '${MODULE_PASCAL} Page',
          style: TextStyle(fontSize: 16.sp),
        ),
      ),
    );
  }
}
EOF

    cat > "$BASE/lib/src/config/feature_${MODULE_NAME}_route.dart" << EOF
import 'package:auto_route/auto_route.dart';
import 'package:feature_${MODULE_NAME}/src/pages/${MODULE_NAME}_page.dart';

@AutoRouterConfig()
class Feature${MODULE_PASCAL}Route extends RootStackRouter {
  @override
  List<AutoRoute> get routes {
    return [
      AutoRoute(page: ${MODULE_PASCAL}Route.page),
    ];
  }
}
EOF

    cat > "$BASE/lib/src/config/feature_${MODULE_NAME}_config.dart" << EOF
import 'package:library_common/library_common.dart';
import 'package:feature_${MODULE_NAME}/src/di/di.dart';

class Feature${MODULE_PASCAL}Config extends AppConfig {
  Feature${MODULE_PASCAL}Config._();
  static final Feature${MODULE_PASCAL}Config _instance = Feature${MODULE_PASCAL}Config._();
  static Feature${MODULE_PASCAL}Config getInstance() {
    return _instance;
  }

  @override
  Future<bool> config({required String env}) async {
    configureInjection(env: env);
    return true;
  }
}
EOF

    cat > "$BASE/lib/src/di/di.dart" << 'EOF'
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'di.config.dart';

final getIt = GetIt.instance;

@injectableInit
void configureInjection({required String env}) {
  getIt.init(environment: env);
}
EOF

    cat > "$BASE/build.yaml" << 'EOF'
targets:
  $default:
    builders:
      freezed:
        generate_for:
          - lib/src/blocs/**
      auto_route_generator|auto_route_generator:
        generate_for:
          - lib/src/config/**
          - lib/src/pages/**
      injectable_generator|injectable_builder:
        generate_for:
          - lib/src/blocs/**
          - lib/src/pages/**
          - lib/src/di/di.dart
EOF

    # Install deps from pub.dev
    echo "    📡 Installing presentation deps..."
    cd "$PROJECT_ROOT/$BASE"
    pub_add auto_route flutter_bloc flutter_screenutil freezed_annotation get_it injectable
    pub_add_dev build_runner auto_route_generator freezed injectable_generator
    cd "$PROJECT_ROOT"
  fi

  echo ""
  echo "✅ Modular module '${MODULE_NAME}' created!"
  echo "   Dependencies resolved to latest versions from pub.dev"
  echo ""
  echo "Next steps:"
  echo "  1. Add package paths to root pubspec.yaml workspace"
  echo "  2. Add Config init to app/lib/injector.dart"
  echo "  3. Add route to app/lib/app_router.dart"
  echo "  4. Run: fvm dart pub get && melos run build"

# ========================================
# SINGLE MODULE PROJECT
# ========================================
else
  APP_NAME=$(grep '^name:' pubspec.yaml | awk '{print $2}')
  echo "  📁 lib/features/${MODULE_NAME}/..."
  BASE="lib/features/${MODULE_NAME}"
  mkdir -p "$BASE"/{domain/{models,repositories,usecases},data/{models,mappers,datasources,repositories},presentation/{blocs/${MODULE_NAME},pages,widgets}}

  cat > "$BASE/domain/models/${MODULE_NAME}_model.dart" << EOF
import 'package:freezed_annotation/freezed_annotation.dart';

part '${MODULE_NAME}_model.freezed.dart';

@freezed
sealed class ${MODULE_PASCAL}Model with _\$${MODULE_PASCAL}Model {
  const factory ${MODULE_PASCAL}Model({
    @Default('') String id,
    @Default('') String name,
  }) = _${MODULE_PASCAL}Model;
}
EOF

  cat > "$BASE/domain/repositories/${MODULE_NAME}_repository.dart" << EOF
import 'package:${APP_NAME}/core/result/result.dart';
import 'package:${APP_NAME}/features/${MODULE_NAME}/domain/models/${MODULE_NAME}_model.dart';

abstract class ${MODULE_PASCAL}Repository {
  Future<Result<List<${MODULE_PASCAL}Model>>> get${MODULE_PASCAL}List();
  Future<Result<${MODULE_PASCAL}Model>> get${MODULE_PASCAL}Detail(String id);
}
EOF

  cat > "$BASE/domain/usecases/get_${MODULE_NAME}_usecase.dart" << EOF
import 'package:injectable/injectable.dart';
import 'package:${APP_NAME}/core/result/result.dart';
import 'package:${APP_NAME}/features/${MODULE_NAME}/domain/models/${MODULE_NAME}_model.dart';
import 'package:${APP_NAME}/features/${MODULE_NAME}/domain/repositories/${MODULE_NAME}_repository.dart';

@lazySingleton
class Get${MODULE_PASCAL}Usecase {
  const Get${MODULE_PASCAL}Usecase(this._repository);
  final ${MODULE_PASCAL}Repository _repository;

  Future<Result<List<${MODULE_PASCAL}Model>>> call() {
    return _repository.get${MODULE_PASCAL}List();
  }
}
EOF

  cat > "$BASE/data/models/${MODULE_NAME}_dto.dart" << EOF
import 'package:freezed_annotation/freezed_annotation.dart';

part '${MODULE_NAME}_dto.freezed.dart';
part '${MODULE_NAME}_dto.g.dart';

@freezed
sealed class ${MODULE_PASCAL}Dto with _\$${MODULE_PASCAL}Dto {
  const factory ${MODULE_PASCAL}Dto({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'name') String? name,
  }) = _${MODULE_PASCAL}Dto;

  factory ${MODULE_PASCAL}Dto.fromJson(Map<String, dynamic> json) {
    return _\$${MODULE_PASCAL}DtoFromJson(json);
  }
}
EOF

  cat > "$BASE/data/mappers/${MODULE_NAME}_model_mapper.dart" << EOF
import 'package:injectable/injectable.dart';
import 'package:${APP_NAME}/features/${MODULE_NAME}/domain/models/${MODULE_NAME}_model.dart';
import 'package:${APP_NAME}/features/${MODULE_NAME}/data/models/${MODULE_NAME}_dto.dart';

@lazySingleton
class ${MODULE_PASCAL}ModelMapper {
  ${MODULE_PASCAL}Model mapFromData(${MODULE_PASCAL}Dto? data) {
    return ${MODULE_PASCAL}Model(
      id: data?.id ?? '',
      name: data?.name ?? '',
    );
  }
}
EOF

  cat > "$BASE/data/datasources/${MODULE_NAME}_remote_datasource.dart" << EOF
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:${APP_NAME}/features/${MODULE_NAME}/data/models/${MODULE_NAME}_dto.dart';

@lazySingleton
class ${MODULE_PASCAL}RemoteDatasource {
  const ${MODULE_PASCAL}RemoteDatasource(this._dio);
  final Dio _dio;

  Future<List<${MODULE_PASCAL}Dto>> get${MODULE_PASCAL}List() async {
    final response = await _dio.get('/${MODULE_NAME}s');
    final list = response.data as List<dynamic>;
    return list.map((e) => ${MODULE_PASCAL}Dto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<${MODULE_PASCAL}Dto> get${MODULE_PASCAL}Detail(String id) async {
    final response = await _dio.get('/${MODULE_NAME}s/\$id');
    return ${MODULE_PASCAL}Dto.fromJson(response.data as Map<String, dynamic>);
  }
}
EOF

  cat > "$BASE/data/repositories/${MODULE_NAME}_repository_impl.dart" << EOF
import 'package:injectable/injectable.dart';
import 'package:${APP_NAME}/core/error/error_mapper.dart';
import 'package:${APP_NAME}/core/result/result.dart';
import 'package:${APP_NAME}/features/${MODULE_NAME}/domain/models/${MODULE_NAME}_model.dart';
import 'package:${APP_NAME}/features/${MODULE_NAME}/domain/repositories/${MODULE_NAME}_repository.dart';
import 'package:${APP_NAME}/features/${MODULE_NAME}/data/datasources/${MODULE_NAME}_remote_datasource.dart';
import 'package:${APP_NAME}/features/${MODULE_NAME}/data/mappers/${MODULE_NAME}_model_mapper.dart';

@LazySingleton(as: ${MODULE_PASCAL}Repository)
class ${MODULE_PASCAL}RepositoryImpl with ErrorMapper implements ${MODULE_PASCAL}Repository {
  const ${MODULE_PASCAL}RepositoryImpl(this._datasource, this._mapper);
  final ${MODULE_PASCAL}RemoteDatasource _datasource;
  final ${MODULE_PASCAL}ModelMapper _mapper;

  @override
  Future<Result<List<${MODULE_PASCAL}Model>>> get${MODULE_PASCAL}List() async {
    try {
      final response = await _datasource.get${MODULE_PASCAL}List();
      return Result.ok(response.map(_mapper.mapFromData).toList());
    } catch (e) {
      return Result.error(mapToFailure(e));
    }
  }

  @override
  Future<Result<${MODULE_PASCAL}Model>> get${MODULE_PASCAL}Detail(String id) async {
    try {
      final response = await _datasource.get${MODULE_PASCAL}Detail(id);
      return Result.ok(_mapper.mapFromData(response));
    } catch (e) {
      return Result.error(mapToFailure(e));
    }
  }
}
EOF

  cat > "$BASE/presentation/blocs/${MODULE_NAME}/${MODULE_NAME}_bloc.dart" << EOF
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:${APP_NAME}/core/result/result.dart';
import 'package:${APP_NAME}/features/${MODULE_NAME}/domain/models/${MODULE_NAME}_model.dart';
import 'package:${APP_NAME}/features/${MODULE_NAME}/domain/usecases/get_${MODULE_NAME}_usecase.dart';

part '${MODULE_NAME}_bloc.freezed.dart';
part '${MODULE_NAME}_event.dart';
part '${MODULE_NAME}_state.dart';

@injectable
class ${MODULE_PASCAL}Bloc extends Bloc<${MODULE_PASCAL}Event, ${MODULE_PASCAL}State> {
  ${MODULE_PASCAL}Bloc(this._get${MODULE_PASCAL}Usecase) : super(const ${MODULE_PASCAL}State()) {
    on<_InitEvent>(_initEvent);
  }

  final Get${MODULE_PASCAL}Usecase _get${MODULE_PASCAL}Usecase;

  Future<void> _initEvent(
    _InitEvent event,
    Emitter<${MODULE_PASCAL}State> emit,
  ) async {
    emit(state.copyWith(${MODULE_NAME}State: const Get${MODULE_PASCAL}State.loading()));
    final result = await _get${MODULE_PASCAL}Usecase();
    switch (result) {
      case Ok(:final value):
        emit(state.copyWith(${MODULE_NAME}State: Get${MODULE_PASCAL}State.done(value)));
      case Error(:final error):
        emit(state.copyWith(${MODULE_NAME}State: Get${MODULE_PASCAL}State.error(error)));
    }
  }
}
EOF

  cat > "$BASE/presentation/blocs/${MODULE_NAME}/${MODULE_NAME}_event.dart" << EOF
part of '${MODULE_NAME}_bloc.dart';

@freezed
abstract class ${MODULE_PASCAL}Event with _\$${MODULE_PASCAL}Event {
  const factory ${MODULE_PASCAL}Event.init() = _InitEvent;
}
EOF

  cat > "$BASE/presentation/blocs/${MODULE_NAME}/${MODULE_NAME}_state.dart" << EOF
part of '${MODULE_NAME}_bloc.dart';

@freezed
abstract class ${MODULE_PASCAL}State with _\$${MODULE_PASCAL}State {
  const factory ${MODULE_PASCAL}State({
    @Default(Get${MODULE_PASCAL}State.idle()) Get${MODULE_PASCAL}State ${MODULE_NAME}State,
  }) = _${MODULE_PASCAL}State;
}

@freezed
abstract class Get${MODULE_PASCAL}State with _\$Get${MODULE_PASCAL}State {
  const factory Get${MODULE_PASCAL}State.idle() = _Get${MODULE_PASCAL}IdleState;
  const factory Get${MODULE_PASCAL}State.loading() = Get${MODULE_PASCAL}LoadingState;
  const factory Get${MODULE_PASCAL}State.done(List<${MODULE_PASCAL}Model> items) = Get${MODULE_PASCAL}DoneState;
  const factory Get${MODULE_PASCAL}State.error(Failure failure) = Get${MODULE_PASCAL}ErrorState;
}
EOF

  cat > "$BASE/presentation/pages/${MODULE_NAME}_page.dart" << EOF
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

@RoutePage()
class ${MODULE_PASCAL}Page extends StatelessWidget {
  const ${MODULE_PASCAL}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${MODULE_PASCAL}',
          style: TextStyle(fontSize: 18.sp),
        ),
      ),
      body: Center(
        child: Text(
          '${MODULE_PASCAL} Page',
          style: TextStyle(fontSize: 16.sp),
        ),
      ),
    );
  }
}
EOF

  echo ""
  echo "✅ Single-module feature '${MODULE_NAME}' created!"
  echo "   (Dependencies already in project pubspec.yaml)"
  echo ""
  echo "Next steps:"
  echo "  1. Add route to lib/app_router.dart"
  echo "  2. Run: fvm dart run build_runner build --delete-conflicting-outputs"
fi
