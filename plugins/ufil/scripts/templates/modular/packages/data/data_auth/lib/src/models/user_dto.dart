import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_dto.freezed.dart';
part 'user_dto.g.dart';

/// Wire format for User. All fields nullable + @JsonKey on EVERY field.
/// NO `.toModel()` — mapping lives in `UserModelMapper` (separate class).
@freezed
abstract class UserDto with _$UserDto {
  const factory UserDto({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'name') String? name,
    @JsonKey(name: 'email') String? email,
  }) = _UserDto;

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return _$UserDtoFromJson(json);
  }
}
