import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../error/failures.dart';

/// Every use case takes a single [Params] object and returns Either a
/// [Failure] or a [SuccessType]. This keeps the Bloc layer decoupled from
/// repository/data-source implementation details.
abstract class UseCase<SuccessType, Params> {
  Future<Either<Failure, SuccessType>> call(Params params);
}

/// Marker class for use cases that take no parameters.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
